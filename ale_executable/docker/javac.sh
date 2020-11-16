#!/usr/bin/env bash

echo "$(pwd): $@: ${@:$#:1}:${@:$#-1:1}:${@:1:$#-1}" >/tmp/test
classpath="."
while [ x$1 != x ] ;do
    case "$1" in
        -X*) option=$1; shift;;
        -cp) 
            echo $2 | egrep -i 'ERROR|WARNING' || classpath=$2; shift 2;;
        -sourcepath) sourcepath=$2; shift 2;;
        -d) outdir=$2; outopt="-d $2";shift 2;;
        *) break;
    esac
done
tdir=`dirname $1`
target=`basename $1`

gradle_path=$(find /data -name build.gradle 2>/dev/null)
gradle_path=$(dirname $gradle_path 2>/dev/null)

if [ -x gradle ] && [ x$gradle_path != x ];then
    cd $gradle_path
fi

echo option=$option cp=$classpath sp=$sourcepath outdir=$outdir tdir=$tdir t=$target >>/tmp/test

exec docker run -i --rm -v "$(pwd):/data" gradle:jdk8 \
    sh -c "[ x${outdir} != x ] && mkdir -p ${outdir} && \
    mkdir -p ${tdir} && \
    cp /data/${target} ${tdir} && \
    javac ${option} -cp ${classpath} -sourcepath ${sourcepath} ${outopt} ${tdir}/${target}"
#exec docker run -i --rm -v "$(pwd):/data" openjdk:8 javac $@
