%Perform batch testing of the main functionalities of the WFBD App Toolbox
clear all;close all;clc

%The test generates and removes temporary files, so it is best run it in a
%specific directory.
total=0;
total_failed=0;
total_time=0;

test_suite={'test_ann2rr','test_physionetdb', ...
    'test_rdann','test_rdsamp','test_sqrs', 'test_gqrs', ...
    'test_tach','test_wfdbdesc','test_wfdbtime', ...
    'test_wqrs','test_wrann','test_wrsamp','test_wfdbdemo',...
    'test_bxb','test_sumann','test_sortann', ...
    'test_wabp','test_mrgann','test_lomb','test_rdmimic2wave', ...
    'test_msentropy','test_edr','test_ecgpuwave','test_woody',...
    'test_mat2wfdb','test_wfdb2mat','test_dfa','test_snip'};
M=length(test_suite);
display(['***Running ' num2str(M) ' test suites...']);


%Start with the installation test, provides a good initial assessment.
failed={};
for m=1:M
    fprintf(['Testing Suite (%s/%s):  %s() ...\n'],num2str(m), num2str(M),test_suite{m});
    eval(['[tests,pass,perf]=' test_suite{m} '();'])
    fprintf(['\tTested: %s\tPassed: %s\tTotal Time= %s\n'],num2str(tests),...
        num2str(pass),num2str(sum(sum(perf))));
    total=total+tests;
    total_failed=total_failed+ (tests-pass);
    total_time=total_time+sum(perf);
    if(pass < tests)
        failed(end+1)=test_suite(m);
    end
end

fprintf(['***Finished all tests!!\n']);
fprintf(['\tTotal test:\t%s\n'], num2str(total));
fprintf(['\tTotal time:\t%s\n'], num2str(total_time));
fprintf(['\tTotal failed:\t%s\n'], num2str(total_failed));
if(total_failed>0)
    fprintf(['\tFailed tests:\n\t']);
    display(failed)
end
