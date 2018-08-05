#!/bin/sh
JAVA_HOME=/usr/java/jre1.7

[ $# -lt 1 ]  &&
{
echo "usage: $0 <help> <tlv file name> [config file[;config file]] [output file]"
exit 1
}

filename=$1

[ ! -e $filename ] &&
{
echo "File $filename does not exist!"
exit 1
}
$JAVA_HOME/bin/java -jar tracesViewer.jar *
