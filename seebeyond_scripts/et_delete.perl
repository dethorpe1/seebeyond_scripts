#! /usr/bin/perl -w

# This script deletes all mesages of a given event type from a queue, topic or both

use strict;

sub usage ()
{
	print "Script to delete a given event type from a JMS queue or Topic\n";
	print "usage: $0 <EventType> <Queue Port> [Type]\n";
	print "       Type = [Q]ueue, [T]opic or [B]oth. Default is Queue\n";
}

sub delMessages($$$)
{
    my ($EventType, $Port, $DelType) = @_;
    my ($DelOption,$ListOption,$ListMsgOption,$JmsType);
    my $NumMessages=0;
    
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
    system("stcmsctrlutil -host localhost -port $Port $ListOption");
    
    # Loop round the list of events on the queue/topic
    open ( STC_UTIL, "stcmsctrlutil -host localhost -port $Port $ListMsgOption $EventType 0 1000 |" ) 
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
    
    		system ("stcmsctrlutil -host localhost -port $Port $DelOption $EventType $SeqNum");
    	}
    }
    close (STC_UTIL);
    
    print ("Deleted $NumMessages Messages of type $EventType from $JmsType on port $Port\n\n");

}      

############################
# START OF MAIN PROCESSING #
############################

my ($DelType);

# check arguments
if (@ARGV < 2 || @ARGV > 3)
{
	usage;
	exit 1;
}

# get type of deletion 
if (defined $ARGV[2])
{
    $DelType = $ARGV[2];
}
else # default is Queue
{
    $DelType = "Q";
}   

if ($DelType eq "B")
{
    # delete both Queue and Topic
    delMessages($ARGV[0], $ARGV[1], "Q");
    delMessages($ARGV[0], $ARGV[1], "T");
}
else
{
    # Just delete the type specified
    delMessages($ARGV[0], $ARGV[1], $DelType);
}

