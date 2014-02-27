#! /usr/bin/perl -w

use strict Vars;
use POSIX qw(strftime);

my( $JmsQ, $SleepTime, $QCount, @Status, $GrowthRate);

my( @JmsQArray ) = 
		( 
		  { NAME => "Queue1",HOST => "localhost",PORT => 41621,LASTCOUNT => 0 },
		  { NAME => "Queue2",HOST => "localhost",PORT => 41622,LASTCOUNT => 0 },
		  { NAME => "Queue3",HOST => "localhost",PORT => 41623,LASTCOUNT => 0 }
		);

$SleepTime=60;
while (1)
{
	print (" ----- " . strftime("%H:%M:%S", localtime()) . " ------ \n" );
	foreach $JmsQ (@JmsQArray)
	{
		@Status=`stcmsctrlutil -host $JmsQ->{HOST} -port $JmsQ->{PORT} -status | egrep -i "retained"`;
		chomp (@Status);
		$QCount=(split(/: /, $Status[0]))[1]; # Messages on Queue
		# work out growth rate for this iteration
		$GrowthRate=($QCount-$JmsQ->{LASTCOUNT})*(60/$SleepTime);
 		print ("$JmsQ->{NAME}: Messages on Queue = $QCount, Growth Rate = $GrowthRate\n");
		# remember last count for this iteration
		$JmsQ->{LASTCOUNT}=$QCount;
	}
	
	sleep ($SleepTime);
}
