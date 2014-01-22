#! /bin/bash

#File used to generated HTML documention for functions of the toolbox.
#Should be run from the directory in which it is located.

#Written by Ikaro Silva 2014

for i in `grep -nr %endOfHelp ./mcode/ | sed 's/:%.*//'`
do 
    lineEnd=$(( ${i##.*:} -1 ))
    fname=${i%%:*}
    func=${fname##.*/}
    func=${func%%.*}
    help=`head -n ${lineEnd} ${fname} | sed 's/%//'`

    #Generate  HTML for the M file
    cat ./mcode/html/template.html | sed "s/MYFUNC/${func}/g" > ./mcode/html/${func}2.html
    echo "${help}" >>./mcode/html/${func}2.html
    cat ./mcode/html/template_bottom.html >> ./mcode/html/${func}2.html

    echo "Generated file: ./mcode/html/${func}.html"    
done


echo "Finished generated doc files"