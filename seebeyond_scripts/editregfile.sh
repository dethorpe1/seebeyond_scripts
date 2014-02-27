#! /usr/bin/ksh
# Script to check out edit and promote a particuler file for a schema

if [[ $# -lt 1 ]]
then
	echo "\nScript to check out edit and promote a particuler file for a schema"
	echo "\nusage: $(basename $0) <egate user> <Registry Dir> <file>"
	echo "   (user must have entry in /egate/client/.egate.stcpass)\n"
	exit 0
fi
	
USER=$1
RegDir=$2
FileToEdit=$3

doreg.sh GET $RegDir $FileToEdit $USER

echo "####  File checked out to sandbox. Press Enter to Edit file, Ctrl-C to abort >"
read $key

vi /egate/server/registry/repository/$EGATE_SCHEMA/sandbox/${USER}${RegDir}/$FileToEdit

echo "
####  Press Enter to promote file to runtime, Ctrl-C to abort >"
read $key

doreg.sh PUT $RegDir $FileToEdit $USER

