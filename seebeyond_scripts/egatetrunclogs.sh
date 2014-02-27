#! /usr/bin/ksh

###########################
#
# script to truncate files specified by pattern, used to reset a set of egate logs
# as they can't just be deleted while the server is runing
# 
# Takes list of files as parameters, this can specific file/s or a shell
# glob pattern. e.g. 
#
#     egatetrunclogs.sh file1.log file2.log file3.log
#     egatetrunclogs.sh *.log
#
###########################

echo "### Files to be truncated:
 $@"
echo "### Will truncate files listed above, Are you sure (Y/N) >"
read key

if [[ "$key" == "Y" ]]
then
	for file in $@ 
	do
	  echo "Truncating $file ..."
	  cat /dev/null > $file
	done
else
	echo "### Truncation Aborted!"
fi
