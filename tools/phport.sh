#!/bin/sh 
# +----------------------------------------------------------------------+
# | PHP Version 4                                                        |
# +----------------------------------------------------------------------+
# | Copyright (c) 1997-2002 The PHP Group                                |
# +----------------------------------------------------------------------+
# | This source file is subject to version 2.02 of the PHP licience,     |
# | that is bundled with this package in the file LICENCE and is         |
# | avalible through the world wide web at                               |
# | http://www.php.net/license/2_02.txt.                                 |
# | If uou did not receive a copy of the PHP license and are unable to   |
# | obtain it through the world wide web, please send a note to          |
# | license@php.net so we can mail you a copy immediately                |
# +----------------------------------------------------------------------+
# | Authors:    Jan Lehnardt <jan@php.net>                               |
# |             Sebastian Nohn <nohn@php.net>                            |
# +----------------------------------------------------------------------+
# 
# $Id: phport.sh,v 1.25 2003-01-16 17:00:16 nohn Exp $

#  The PHP Port project should provide the ability to build and test 
#  any PHP4+ Version with any module/webserver.

# Variable declaration
USE_BZ2=NO
TRY_ZE2=NO

PREFIX="/tmp"
DISTFILESDIR="$PREFIX/distfiles"
WRKDIR="$PREFIX/work"
ETCDIR="$PREFIX/etc"
PHPSNAPFILEPREFIX="php5-latest.tar"
PHPSNAPSERVER="http://snaps.php.net/"
PHPCVSSERVER=":pserver:cvsread@cvs.php.net:/repository"
PHPCVSPASS="A:c:E?"
MAKE=${MAKE:=make}

# functions
usage() {
    cat <<EOF
    $1 mode [argument]
    mode: 
     - snap    Builds from a Snapshot requires remote archive 
               in argument (http/ftp)
     - cvs     Builds from CVS
     - local   Builds from the local sourcetree specified in argument
EOF
}

makedir() { mkdir "$@" || exit 1  ; }

# Build directory structure if not available
if ! [ -d "$PREFIX" ] ; then
    makedir $PREFIX
fi

if ! [ -d "$WRKDIR" ] ; then
    for i in / /php5-cvs /php5-snap /php5-local ; do
        makedir $WRKDIR"$i"
    done
fi           

if ! [ -d "$DISTFILESDIR" ] ; then
    for i in / /cvs ; do
        makedir $DISTFILESDIR"$i"
    done
fi

if ! [ -d $ETCDIR ] ; then
    makedir $ETCDIR
fi    


# Detect mode (snap|cvs|local)
case $1 in 
    snap|cvs|local) 
        MODE=$1
        ;;
    *)
    echo "Invalid Mode"
    usage $0
    exit 1
    ;;
esac
echo $MODE

# Clean $WRKDIR 
rm -rf "$WRKDIR/php5-$MODE/*"
# Fetch/extract source to $DISTFILESDIR/$WRKDIR
case $MODE in
    snap) # 24h distfile!!
        if [ $2 ] ; then
            SNAPURI=$2;
            PHPSNAPFILE="`echo $SNAPURI | sed 's#.*/##'`"
        elif [ "$USE_BZ2" = "NO" ] ; then 
            PHPSNAPFILE="$PHPSNAPFILEPREFIX"".gz"
            SNAPURI=$PHPSNAPSERVER/$PHPSNAPFILE
        else
            PHPSNAPFILE="$PHPSNAPFILEPREFIX"".bz2"
            SNAPURI=$PHPSNAPSERVER/$PHPSNAPFILE
        fi

        if [ -s "$PHPSNAPFILE" ] ; then
            cp $PHPSNAPFILE "$DISTFILESDIR"
        else
            if [ -x "`which fetch`" ] ; then
                FETCHCMD="fetch -m -o \"$DISTFILESDIR/$PHPSNAPFILE\" $SNAPURI"
            elif [ -x "`which wget`"] ; then
                FETCHCMD="wget -O \"$DISTFILESDIR/$PHPSNAPFILE\" $SNAPURI"
            fi    
            if  ! [ -s "$DISTFILESDIR/$PHPSNAPFILE" ] ; then 
                echo "$PHPSNAPFILE does not seem to exist in $DISTFILESDIR, downloading..."
                $FETCHCMD
            fi
	fi
        echo "Extracting source package..."

    # see if we have gzip or bzip2

    EXT="`echo $PHPSNAPFILE | sed -e 's/.*\.//'`";
    
    # Keep it portable
    if [ $EXT = "gz" ] ; then
        COMPRESSOR=gzip
    elif [ $EXT = "bz2" ] ; then
        COMPRESSOR=bzip2
    else
        echo "Unknown package format";
        exit 1;
    fi

    $COMPRESSOR -cd "$DISTFILESDIR/$PHPSNAPFILE" | (cd "$WRKDIR/php5-$MODE" && tar -xf -)
        mv -f "$WRKDIR/php5-$MODE/php*/*" "$WRKDIR/php5-$MODE"
        
    ;;

    cvs)
        if ! [ -f ~/.cvspass ] || [ `grep -c cvsread@cvs.php.net ~/.cvspass` -lt 1 ] ; then
            echo $PHPCVSSERVER $PHPCVSPASS>> ~/.cvspass
        fi 
        cd "$DISTFILESDIR/$MODE" || exit 1

                cvs -d $PHPCVSSERVER co php4
                    cd php4
                        if [ "$TRY_ZE2" = "NO" ] ; then
                # do nothing - it's a "symlink" cvs -d $PHPCVSSERVER co Zend TSRM
                # but we need to do something here, otherwise the script would fail...
                            echo
                         else
                            cvs -z3 -d $PHPCVSSERVER co -d Zend ZendEngine2 TSRM
                        fi 
                        # cpio: command not found
                        # find . | cpio -pdm "$WRKDIR/php4-$MODE"
            tar -cf - . | (cd "$WRKDIR/php5-$MODE" && tar -xf -)
                    cd ../../..
                    
    ;;
    
    local)
        if [ -n "$2" ] ; then
            cd $2
            tar -cf - . | (cd "$WRKDIR/php5-$MODE" && tar -xf -)
        else
            echo "No local Path supplied"    
            exit 1
        fi    
    ;;
esac    

# Get configure options
if [ -f "$ETCDIR/configure-options" ] ; then
    for option in `cat $ETCDIR/configure-options` ; do
        options="$options $option"
    done    
fi
# Check dependencies of configured extensions
# Clean dependencies
# Fetch/extract source into $DISTFILESDIR/$WRKDIR
# Build dependencies
# Install dependencies (Libraries) locally
  
# Configure PHP
cd "$WRKDIR/php5-$MODE"
if [ ! -s ./configure ] ; then
    ./cvsclean || exit 1
    ./buildconf || exit 1
fi
./configure $options

# Clean
$MAKE clean
if [ $? -gt 0 ]; then
    echo "Clean had problems. Thing may go down hill from this point on"
    sleep 1
fi
# Build PHP
$MAKE 2>error.log
# Install PHP locally

# Mail the compile-errors & warnings...
cat error.log | mail -s "PHP Compile Report" $USER

# Running testcases against the environment
NO_INTERACTION=1
export NO_INTERACTION
$MAKE test | mail -s "PHP Test Report" $USER

# vim600: et ts=4 sw=4