#! /usr/bin/perl -w

# This script monitors a set of eGate JMS queues defined in the JmsQArray structure
# and prints the number of messages processes each minute and the totals so far.

use strict;

my( $JmsQ, $Total, $SleepTime, $SCount, $QCount, @SibUpdate, $ThroughPut);

my( @JmsQArray ) = 
		( {
		  HOST => "localhost",
		  PORT => 51620,
		  QUEUE => "queue1",
		  LASTCOUNT => 0 },
		 {
		  HOST => "localhost",
		  PORT => 51621,
		  QUEUE => "queue2",
		  LASTCOUNT => 0 },
		 {
		  HOST => "localhost",
		  PORT => 51622,
		  QUEUE => "queue3",
		  LASTCOUNT => 0 }
 );

$SleepTime=60;
while (1)
{
        # Base number of messages 
        $Total=0;

	foreach $JmsQ (@JmsQArray)
	{
		@SibUpdate=`stcmsctrlutil -host $JmsQ->{HOST} -port $JmsQ->{PORT} -queuestat $JmsQ->{QUEUE} | egrep -i "Message count|committed"`;
		chomp (@SibUpdate);
		$QCount=(split(/: /, $SibUpdate[0]))[1]; # Messages on Queue
		$SCount=(split(/: /, $SibUpdate[1]))[1]; # Messages Sent
		$Total+=$SCount;
		# work out throughput for this iteration
		$ThroughPut=($SCount-$JmsQ->{LASTCOUNT})*(60/$SleepTime);
 		print ("$JmsQ->{HOST}:$JmsQ->{QUEUE}: Messages on Queue = $QCount, Messages sent and commited = $SCount, Throughput = $ThroughPut\n");
		# remember last count for this iteration
		$JmsQ->{LASTCOUNT}=$SCount;
	}
	print ("TOTAL = $Total\n");
	sleep ($SleepTime);
}
