#!/bin/ksh
#set -xv

###########################################################################
# Global variables
###########################################################################
SYSTEM_NAME="" ; export SYSTEM_NAME
ENCRYPTED_PASSWORD=""  ; export ENCRYPTED_PASSWORD
WORK_DIR="/tmp" ; export WORK_DIR

###########################################################################
# usage
###########################################################################
usage()
{
 [ "$SYSTEM_NAME" = "" ] && echo "No system name!"
 [ "$ENCRYPTED_PASSWORD" = "" ]  && echo "no password!"
 echo "Usage : `basename $0` -u <user> -p <encrypted password>"
 exit 0
}

###########################################################################
# verify input params
###########################################################################
while getopts ":u:p:h" opt; do
  case $opt in
  h )  usage ;;
  u )  SYSTEM_NAME="$OPTARG" ;;
  p )  ENCRYPTED_PASSWORD="$OPTARG"  ;;
  \?)  usage ;;
  esac
done
shift $(($OPTIND - 1))

[ "$SYSTEM_NAME" = "" ] && usage
[ "$ENCRYPTED_PASSWORD" = "" ]  && usage

###########################################################################
# launch password decrypt script
###########################################################################
# Creation monk script

rm -f $WORK_DIR/kiagenpwd_$$.txt
touch $WORK_DIR/kiagenpwd_$$.txt
(
echo \(load-extension \"/egate/client/bin/stc_monkext.dll\"\)
echo \(load-extension \"/egate/client/bin/stc_monkutils.dll\"\)
echo \(display \(string-append \"\<PASSWORD\>\" \(string-decrypt\"$SYSTEM_NAME\" \"$ENCRYPTED_PASSWORD\"\) \"\<PASSWORD\>\"\)\) \(newline\)) >> $WORK_DIR/kiagenpwd_$$.txt

# launch monk script
PWD_CRYPT=`stctrans -md $WORK_DIR/kiagenpwd_$$.txt | grep "<PASSWORD>" | nawk -F"<PASSWORD>" '{printf("%s", $2);}'`

# remove monk script
# rm -f $WORK_DIR/kiagenpwd_$$.txt

echo "$PWD_CRYPT"

return 0

