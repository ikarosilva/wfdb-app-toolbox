# Introduction #

The toolbox requires that the Octave package Java be installed. The package
website can be found at:
http://wiki.octave.org/Java_package

Below is a series of configuration steps to get Octave to work with the toolbox in Linux Debian. For other systems please see the Java package link above.


# Details #

#Configure Java for Octave and install Java package:

ln -s /usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server
/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/client

apt-get install liboctave-dev

octave --eval  "setenv(\"JAVA\_HOME\",\"/usr/lib/jvm/java-7-openjdk-amd64\");pkg
install -forge java;quit;"

#Optional: Test installation:

octave --eval  "s=javaObject(\"java.lang.String\",\"Install
Good!!\");display(s);quit;"