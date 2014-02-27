#! /usr/bin/ksh

#######################
#
# Script to perform source control actions on files in egate registry
#
# Usage:
#    doreg <action> <path> <file> <user>
#
#      <action> - Action to perform [ GET | PUT | DEL ] 
#                 GET = retreive file into users sandbox
#		  PUT = Promote file from users sandbox to runtime
#                 DEL = Delete file from users sandbox
#      <path> - registry path for file
#      <file> - file to take action on
#      <user> - eGate user to use
#
########################

if [[ $# -ne 4 ]]
then
	echo "\nScript to perform source control actions on files in egate registry"
	echo "\nUsage: $(basename $0) [GET|PUT|DEL] <registry path> <file name> <egate user>"
	echo "   (user must have entry in /egate/client/.egate.stcpass)\n"
	exit 0
fi
	
REG_ACTION=$1
REG_PATH=$2
REG_FILE=$3
REG_USER=$4
EGATE_SANDBOX=$EGATE/registry/repository/$SCHEMA/sandbox/$REG_USER

case $REG_ACTION in
	"GET")
		action=fvce
		echo "retreiving file $REG_FILE to sandbox ..."
		;;
	"PUT")
		action=fvcp
		# remove from client to make sure new file used
		echo "Removing $REG_FILE from client to make sure new file used ..."
		rm ~/client/"${REG_PATH}/${REG_FILE}"
		REG_FILE=$EGATE_SANDBOX/$REG_PATH/$REG_FILE
		echo "promoting file $REG_FILE from sandbox to runtime ..."
		;;
	"DEL")
		action=fvcu
		REG_FILE=$EGATE_SANDBOX/$REG_PATH/$REG_FILE
		echo "Deleting file $REG_FILE from sandbox ..."
		
		;;
	*) echo "Invalid option: $REG_ACTION"
		echo "Usage: doreg.sh <action> <path> <file>"
		exit
		;;
esac

stcregutil -rh $REGHOST -rs $SCHEMA -un $REG_USER -up !/egate/client -${action} "$REG_PATH" "$REG_FILE"

echo "[DONE - If no message from stcregutil above then has not worked !!]"

