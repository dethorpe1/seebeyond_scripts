#!/usr/bin/ksh
################################################################################
#
# SCRIPT:      queueCounts [-c <config file name> ] | [-p port [ -h host ] ]
#
# PARAMETERS:  
#               -c config file name. File containing list of ports to check, Overrides host and port options
#				-p queue and port, same format as in config file(i.e. name:port). 
#					Queue name can be omitted, if so port is used as name.
#				-h host, used with port. If absent localhost is used
#
# CONFIG FILE FORMAT:
#
#  Entries should appear in the config file as follows:
#
#   PORTS=<host>:<iq manager display name>:<iq manager port>
# 
#  e.g.
#   PORTS=localhost:LocalQueue1:41623
#   PORTS=hostname:RemoteQueue2:41622
#
# DESCRIPTION:
#
#  Script to return details of messages processed/pending for e*Gate Q mgrs
#  Calls e*Gate utility stcmsctrlutil to get Q list for a mgr and then
#  to get information for each Q returned
#  Gets list of queues and hosts from a specified config file, or a single queue can be 
#  specified on the command line
#
################################################################################

DEBUG=false

debugPrint()
{
	if [[ $DEBUG == "true" ]]
	then
		print "DEBUG:$1"
	fi
}
################################################################################
# READ COMMAND LINE
################################################################################

while getopts c:p:h: options 2>>/dev/null; do
    case $options in
      c) CONFIG_FILE=$OPTARG;;
	  p) PORT=$OPTARG;;
	  h) EGATE_PARTHOST=$OPTARG;;
      *) echo Invalid parameters;;
    esac
done

################################################################################
# THE MAIN BIT
################################################################################

# if config file specified used get list of ports from it, otherwise use specified port

if [[ ! -z "${CONFIG_FILE}" ]]
then
	if [[ ! -r "${CONFIG_FILE}" ]]
	then
   		print "Config file ${CONFIG_FILE} is not readable"
  	  	exit 1
	fi

	# get the list of ports to check from the config file
        PORTS="`awk -F"=" '/QUEUE_START/,/QUEUE_END/ {if ($1 == "PORTS") print $2;}' ${CONFIG_FILE}`"
else 
	if [[ ! -z "${PORT}" ]]
	then
		if [[ -z "$EGATE_PARTHOST" ]]
		then
			EGATE_PARTHOST=localhost
		fi
		PORTS="$EGATE_PARTHOST:$PORT:$PORT" # add the port twice so if name not given just get the number
	else
		print "ERROR: invalid arguments. Config file or host/port must be specified"
		exit 1
	fi
fi
	
# Now loop through the list of ports displaying the stats for each

for port in ${PORTS}
do

	debugPrint "port=$port"
	parthost=$(echo ${port} | cut -d: -f1)
    iqm=$(echo ${port} | cut -d: -f2)
    iqmport=$(echo ${port} | cut -d: -f3)

    QLIST=`stcmsctrlutil -host ${parthost} -port ${iqmport} -queuelist`
	if [[ $? > 0 ]]
	then
		# No such queue, so continue to the next one
		continue
	fi
	debugPrint "QLIST=$QLIST"

	# Get the list of queues (event types)
    QLIST=`echo "$QLIST" | tail +3 | sed -e 's/ //g'`
	debugPrint "QLIST(2)=${QLIST}"

	# loop through the list of queues and add up the totals for the manager
    CountTotal=0
    SentTotal=0
	ReceiversTotal=0
    for Q in ${QLIST}
    do

        OutLine=`stcmsctrlutil -host ${parthost} -port ${iqmport} -queuestat ${Q} | egrep -e "committed|Message count|receivers"`
		debugPrint "$OutLine"
		Count=`echo $OutLine | nawk -F"[	 ]+" '{ print $8 }'`
		Sent=`echo $OutLine | nawk -F"[	 ]+" '{ print $13 }'`
		Receivers=`echo $OutLine | nawk -F"[	 ]+" '{ print $5 }'`
		let CountTotal=$CountTotal+$Count
		let SentTotal=$SentTotal+$Sent
		let ReceiversTotal=$ReceiversTotal+$Receivers
    done
	print "${parthost}:${iqm}:${iqmport},MessageCount:$CountTotal,SentAndCommitted:$SentTotal,TotalReceivers:$ReceiversTotal"

done

################################################################################
# THE END
################################################################################
