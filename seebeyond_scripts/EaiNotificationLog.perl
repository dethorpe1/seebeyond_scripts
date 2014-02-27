#! /usr/bin/perl -w

# This script is used to add entries to an egate notification log detailing alerts recieved for components.
# It is designed to be called from the Control brokers notification script (notification.tsc) using the script channel, but can
# also be called from the command line and hence used by any process wanting to log component status information. To be run
# by the control broker it must exist in a directory on the PATH of the egate client user the control broker is run as, 
# normally $HOME/egate/client/bin
#
# It filters alerts based on a reguler expression applied to the notification Code to only log those of interest.
# Currently only logs component failures, this can be expended as necassary if other alerts are required. If the alert
# is not one to be logged the script exits silently with an OK status.
#
# The alerts are logged to a file called Notification_log-YYYYMMDD.log, this will be assumed to be in the users
# egate/client/notificationlogs directory (under the $HOME dir), but can be overridden by setting the EGATE_NOTIFICATIONLOG_DIR environment
# variable to specify a different directory.
#
# The log file is '|' seperated and has the following format:
#	ERR-CODE-xxxx|TimeStamp|Severity|notification code|component name|Message
#
# The Error code (xxxx above) is a list of codes used to indicate the type of alert, the current set is:
#	8001 = Component has failed in an uncontrolled manner (SIGKILL or crash)
#	8002 = Component has been taken down in a controlled manner (SIGTERM or E*gate monitor)

# USAGE:
#		EaiNotificationLog.perl <notificationCode> <severity> <component> <message>
#			notificationCode = 8 byte notification Code supplied in the alert Event Header. 
#			severity = severity code supplied in the alert Event Header.
#			component = name of component that has raised the alert. 
#			messgae = Free text message to go into log. Control Broker generates this by concatenating
#					  the element Name, element Type and Event name from the alert.
#
#	See egate documentation Alert_Log_Reference.pdf for details of the format and contents of the values
#	supplied to the control broker notification script and hence based in the parameters to this script
#
# EXIT CODES:
#	0 - Success, log has been written if required.
#	1 - Invalid arguments
#	2 - notification Code paramter is not 8 bytes long
#	13 - Unable to open log file
#	? - Other unknown errors


use strict;
use POSIX;

sub usage()
{
	print "USAGE: $0 <notificationCode> <severity> <component> <message>\n";
}

# check number of arguments
if ( @ARGV != 4 )
{
	print ("Invalid Number of arguments. Got " . @ARGV . " Expected 4\n");
	usage;
	exit (1);
}

# Get arguments
my ($notificationCode, $severity, $component, $message) = @ARGV;
my $errCode = "1"; # default err code in case anything screws up

# Check notification code is correct format
$! = 2; # set the error code for die if the notificationCode length is incorrect
die "ERROR: NotificationCode must be 8 chars" if ( length($notificationCode) != 8 );


## DECIDE IF NOTIFICATION IS ONE WE SHOULD LOG

if ($notificationCode =~ /101[13V].*/ )
{
	# Its a component Down, Unresponsive or unable to start alert
	$message = $message . ". Component is Down, Unresponsive or can't start.";

	# work out the log Error code based on the egate Notification code
	my @codes = unpack ("a1a1a1a1a1a1a1a1", $notificationCode);
	if ($codes[6] eq '2' ) 	{ $errCode = "8002"; } # component Down controlled
	else 					{ $errCode = "8001"; } # component failed

}
# elsif { Add any more required alerts here # }
else
{
	# Don't want to log so just exit silently
	exit (0);
}

## NOW WRITE TO THE LOG

my @time = localtime;  # current time

# get timestamp for logline
my $dateTime = strftime ("%Y-%m-%d %H:%M:%S", @time);

# get timestamp for log file name
my $logFileDate = strftime("%Y%m%d",@time);
	
# get environment vars and set defaults if not present
my $user 	 = $ENV{"USER"} || $ENV{"LOGNAME"} || "";
my $homeDir  = $ENV{"HOME"} || ".";
my $logPath  = $ENV{"EGATE_NOTIFICATIONLOG_DIR"} || "egate/client/notificationlogs";
	
# Set complete file and pathname for the log file
my $logFilePath = "$homeDir/$logPath/Notification_log-$logFileDate.log";
	
# Generate the | seperated log line
my $logLine = join ( "|", (("ERR-CODE-" . $errCode), $dateTime, $severity, $notificationCode, $user, $component, $message));

# open, print and close
open (LOGFILE, ">>$logFilePath") || die "ERROR: Unable to open notification log file $logFilePath. $!";
print (LOGFILE "$logLine\n") || die "ERROR: Unable to write to notification log file $logFilePath. $!";
close (LOGFILE);

## THE END ##
