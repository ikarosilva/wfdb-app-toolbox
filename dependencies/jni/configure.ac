AC_PREREQ([2.63])
AC_INIT([librdsampjni], [0.9.10], [wfdb-matlab-support@physionet.org])
AC_CONFIG_SRCDIR([rdsampjni.c])

AC_PROG_CC
if test "x$GCC" = "xyes"; then
   CFLAGS="$CFLAGS -W -Wall"
fi

AC_CANONICAL_HOST
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_ARG_VAR([JAVA], [Java interpreter])
AC_ARG_VAR([JAVAH], [JNI header generator])
AC_CHECK_PROGS([JAVA], [java])
AC_CHECK_PROGS([JAVAH], [javah])

# try to guess where JNI headers might be
# (partially inspired by Don Anderson's AC_JNI_INCLUDE_DIR)
AC_ARG_VAR([JAVA_HOME], [JDK installation prefix])
AC_ARG_VAR([JNI_CFLAGS], [C compiler flags for JNI])
if test "x$JNI_CFLAGS" = "x"; then
    if test "x$JAVA_HOME" = "x" && test "x$host_alias" = "x$build_alias"; then
        # If JAVA_HOME not set, and we are not cross-compiling, try to
        # infer it from the location of 'javah' (after following
        # symlinks.)
        AC_PATH_PROG([_JAVAH], [$JAVAH])
        _cur=$_JAVAH
        while ls -ld "$_cur" 2>/dev/null | grep " -> " >/dev/null; do
            AC_MSG_CHECKING(symlink for $_cur)
            _slink=`ls -ld "$_cur" | sed 's/.* -> //'`
            case "$_slink" in
            /*) _cur="$_slink";;
            # 'X' avoids triggering unwanted echo options.
            *) _cur=`echo "X$_cur" | sed -e 's/^X//' -e 's:[[^/]]*$::'`"$_slink";;
            esac
            AC_MSG_RESULT($_cur)
        done
        if test -f "$_cur"; then
            JAVA_HOME=`echo "$_cur" | sed -e 's://*:/:g' -e 's:/[[^/]]*/[[^/]]*$::'`
        fi
    fi
    if test "x$JAVA_HOME" != "x" && test -f "$JAVA_HOME/include/jni.h"; then
        # If JAVA_HOME is known, look for headers there.
        JNI_CFLAGS="-I$JAVA_HOME/include"
        case "$host_os" in
        bsdi*)          subdirs="bsdos";;
        freebsd*)       subdirs="freebsd";;
        darwin*)        subdirs="darwin";;
        linux*)         subdirs="linux genunix";;
        osf*)           subdirs="alpha";;
        solaris*)       subdirs="solaris";;
        mingw*)		subdirs="win32";;
        cygwin*)	subdirs="win32";;
        *)              subdirs="genunix";;
        esac
        for d in $subdirs; do
            if test -d "$JAVA_HOME/include/$d"; then
                JNI_CFLAGS="$JNI_CFLAGS -I$JAVA_HOME/include/$d"
            fi
        done
    else
        # Otherwise try to guess at location for system-provided headers.
        case $host_os in
        darwin*)
            if test "x$cross_compiling" = "xyes"; then
                opt="-iwithsysroot "
            else
                opt="-I"
            fi
            JNI_CFLAGS="$opt/System/Library/Frameworks/JavaVM.framework/Headers/"
            ;;
        esac
    fi
fi

AC_ARG_VAR([WFDB_CFLAGS], [C compiler flags for WFDB])
AC_ARG_VAR([WFDB_LIBS],   [Library flags for WFDB])
if test "x$WFDB_CFLAGS$WFDB_LIBS" = "x"; then
  WFDB_CFLAGS=`wfdb-config --cflags 2>/dev/null`
  WFDB_LIBS=`wfdb-config --libs 2>/dev/null`
fi

cppflags1=$CPPFLAGS
libs1=$LIBS

CPPFLAGS="$cppflags1 $JNI_CFLAGS"
AC_CHECK_HEADER([jni.h], [ : ], [AC_MSG_ERROR([JNI header files not found.])])

CPPFLAGS="$cppflags1 $WFDB_CFLAGS"
LIBS="$WFDB_LIBS $libs1"
AC_CHECK_HEADER([wfdb/wfdb.h], [ : ], [AC_MSG_ERROR([WFDB header files not found.])])
AC_CHECK_FUNC([isigopen], [ : ], [AC_MSG_ERROR([WFDB library not found.])])

CPPFLAGS=$cppflags1
LIBS=$libs1

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
