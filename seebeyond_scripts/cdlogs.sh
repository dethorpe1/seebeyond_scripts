#! /usr/bin/ksh
# Script to Change to the logs directory for a given logical host
# usage ". cdlogs <host>"

path_to_logical_hosts_parent=Set_this_to_the_parent_dir_of_the_lhosts
lhost=$1
if [[ -z $lhost ]] 
then
	# host not specified so provide menu
	hostlist=`ls -1 $path_to_logical_hosts_parent`
	PS3="Select Logical host > "
	select lhost in $hostlist	
	do
		break
	done
fi		

host_root=$path_to_logical_hosts_parent/$lhost
if [[ -d $host_root ]]
then
	echo "## Changing to logs dir for $lhost ..."
	if [[ -e  $host_root/is/logs ]]
	then
		cd $host_root/is/logs
		ls
	elif [[ -e $host_root/is/domains/domain1/logs ]]
	then
		cd $host_root/is/domains/domain1/logs
		ls
	else
		echo "## ERROR: Can't find ICAN or JCAPS host logs dir"
	fi
else
	echo "## ERROR:Host $lhost does not exist"
	exit 1
fi
