#! bash
# #! /usr/bin/ksh

################################################################################
#
# SCRIPT: bulkstcregutil.sh
#
# DESCRIPTION:
#  Script to run stcregutil command on batch of files in a directory.
#  Uses current dir unless -d option specified.
#
# NOTES:
# FUNCTIONS:
# USAGE:
#    bulkstcregutil.sh -h <host> -s <Schema> -u <user> -p <password> [-o <port>] -c <command> -a <param> [-d <dir>] -h
#
################################################################################

function usage()
{
    echo " Script to run stcregutil command on batch of files "
    echo " usage: $0 -h <host> -s <Schema> -u <user> -p <password> [-o <port>] -c <command> -a <param> [-d <dir>] -h"
    exit
}

# debug off unless specified on command line
DEBUG=""
DIR=`pwd` # default is current dir

# Get the command line options and override the defaults as required.
while getopts h:s:u:p:o:c:a:d: name
do
    case $name in
    h)  HOST=$OPTARG;;
    s)  SCHEMA=$OPTARG;;
    u)  USER=$OPTARG;;
    p)  PASSWORD=$OPTARG;;
    o)  PORT="-rp $OPTARG";;
    c)  COMMAND=$OPTARG;;
    a)  PARAM=$OPTARG;;
    d)  DIR=$OPTARG
        cd $DIR
        ;;
    ?)  echo "ERROR: Invalid option '$name'"
        usage;;
    esac
done

# 

FILE_LIST=`ls -1`
echo "Performing command:  -$COMMAND $PARAM"
echo "With registry connection: -rh $HOST -rs $SCHEMA -un $USER -up $PASSWORD $PORT "
for file in $FILE_LIST
do
    echo "File: $file"
    stcregutil -rh $HOST -rs $SCHEMA -un $USER -up $PASSWORD $PORT -$COMMAND $PARAM $file
done
