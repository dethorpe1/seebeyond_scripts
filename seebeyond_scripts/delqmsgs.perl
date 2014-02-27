#! /usr/bin/perl -w

# This script deletes all mesages from a queue, topic or both

use strict;
use Getopt::Std;

sub usage ()
{
	print <<END;
Script to delete all messages from a given JMS queue or Topic.

usage: $0 -m <message> -p <port> [-t type] [-h host]
    message = name of message to delete
    type = [Q]ueue, [T]opic or [B]oth. Default is Queue
    host = JMS server hostname or IP, default is localhost
    port = JMS server port
END
	exit 1;
}

sub delMessages($$$$)
{
    my ($EventType, $Port, $DelType, $host) = @_;
    my ($DelOption,$ListOption,$ListMsgOption,$JmsType);
    my $NumMessages=0;
    $host="localhost" if (!defined $host);

    if ($DelType eq "T")
    {
    	$ListMsgOption="-tml";
    	$ListOption="-topiclist";
    	$DelOption="-dtm";
    	$JmsType="Topic";
    }
    else # default to queue
    {
    	$ListMsgOption="-qml";
    	$ListOption="-queuelist";
    	$DelOption="-dqm";
    	$JmsType="Queue";
    }
    
    # List the Queues or Topics
    system("stcmsctrlutil.exe -host $host -port $Port $ListOption");
    
    # Loop round the list of events on the queue/topic
    open ( STC_UTIL, "stcmsctrlutil.exe -host $host -port $Port $ListMsgOption $EventType 0 1000 |" ) 
			|| die "Unable to run stcmsutil command: $!";

    while (<STC_UTIL>)
    {
    	print if m/Number Of Messages/; # print the number of messages line
    
    	if ( m/Message\.SeqNo/)
    	{
    	    # Got the sequence number line so delete the message
    		chomp;
    		$NumMessages++;
    		my $SeqNum = (split (/=/))[1];
    		print "Deleting Sequence Number: $SeqNum\n";
    
    		system ("stcmsctrlutil.exe -host $host -port $Port $DelOption $EventType $SeqNum");
    	}
    }
    close (STC_UTIL);
    
    print ("Deleted $NumMessages Messages of type $EventType from $JmsType on host $host, port $Port\n\n");

}      

############################
# START OF MAIN PROCESSING #
############################

my %opts;
my $DelType = "Q";
my $host = "localhost";
my ($port,$event);

# get arguments
getopts("e:h:p:t:", \%opts) || usage;

$DelType = $opts{'t'} if defined $opts{'t'};
$host = $opts{'h'} if defined $opts{'h'};
$port = $opts{'p'} if defined $opts{'p'};
$event = $opts{'e'} if defined $opts{'e'};

usage if (!defined $port || !defined $event );

if ($DelType eq "B")
{
    # delete both Queue and Topic
    delMessages($event, $port, "Q", $host);
    delMessages($event, $port, "T", $host);
}
else
{
    # Just delete the type specified
    delMessages($event, $port, $DelType, $host);
}


