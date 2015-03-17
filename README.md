
<p align="center" >
  <img src="http://physionet.org/physiotools/matlab/wfdb-app-matlab/wfdbrecordviewerTB.png" alt="wfdbRecordViewer" title="wfdbRecordViewer" />
</p>

The WFDB Toolbox for MATLAB and Octave is a set of Java, GUI, and m-code wrapper functions,
which make system calls to WFDB Software Package and other PhysioToolkit applications. The
website for the toolbox (along with the installation instructions) can be found at:

http://physionet.org/physiotools/matlab/wfdb-app-matlab/

Using the WFDB Toolbox, MATLAB and Octave users have access to over 50 PhysioBank databases 
(over 4 TB of physiologic signals including ECG, EEG, EMG, fetal ECG, PLETH (PPG), ABP, respiration, and more).
Additionally, most of these databases are also accompanied by metadata such as expert annotations of
physiologically relevant events in WFDB annotation files. These can include, for example, 
cardiologists' beat and rhythm annotations of ECGs, or sleep experts' hypnograms (sleep stage annotations) 
of polysomnograms. All of these physiologic signals and annotations can be read on demand from the
PhysioNet web server and its mirrors using the toolbox functions, or from local copies if you choose 
to download them. This feature allows your code to analyze the wide range of physiologic signals 
available from PhysioBank without the need to download entire records and to store them locally.
The Toolbox is open-source (distributed under the GPL). The toolbox includes a GUI (WFDBRECORDVIEWER)
for facilitating the browsing, exploration, and analysis of WFBD records stored locally on the users machine, 
or remotely in PhysioNet's databases.

A community discussion group forum is available at:

http://groups.google.com/forum/#!forum/wfdb-app-toolbox
