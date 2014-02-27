#! /usr/bin/perl -w

#======================================================================================
#=

=head1 NAME

egatedeltopic.pl - Delete a topic.

=head1 SYNOPSIS

Delete a topic. Deletes all subscribers first.
Presents menu of topics for queue manager if none specified on command line.


USAGE:

  egatedeltopic.pl <port> <topic>

=cut

#=
#======================================================================================

use strict;
use warnings;
use Pod::Usage;
use Carp;

#==========================
#=

=head2 select_topic()

Display menu to allow topic selection

 IN - port: queue manager port
 OUT - topic: Selected topic
 
=cut 

#=
#==========================

sub select_topic {
	my ($port) = @_;
	my ($count,$topic) =(1,undef);
	my %menu=();

	print "\n\n";
	foreach my $line (`stcmsctrlutil.exe -p $port -tl`) {
		if ($line =~ m  {
			             ^      # Beginning of line
				     \s+    # Any Whitespace
				     (.*)   # capture rest of line
				     $      # end of line
				   }x) {
		  	$menu{$count} = $1;
  			print '  ' . $count++ . ") $1\n";
		}
	}
	
	while (!defined $topic) {
		print "\n  ## Select topic to delete > ";
		my $key = <STDIN>;
		chomp $key;
		$topic = $menu{$key};
	}
	return $topic;
}

#==========================
#=

=head2 delete_topic()

Delete the topic

 IN - port: queue manager port
 IN - topic: topic to delete
 
=cut 

#=
#==========================

sub delete_topic {
	my ($port,$topic) = @_;
	my ($subscriber,$client);

	open (my $slft_fh, "-|", "stcmsctrlutil.exe -p $port -slft $topic") || croak "Unable to run slft command. $!";
	while (my $line = <$slft_fh>){
		if ($line =~ m/^Subscriber name:/) {
	  	print $line;
			$subscriber = (split (/ /, $line))[2];
			chomp $subscriber;
		}
		if ($line =~ m/Client ID:/) {
			$line =~ s/^\s+//;
	  	print $line;
			$client = (split (/ /, $line))[2]; 
			chomp $client;
			print "Deleteing Subscriber: $subscriber, Client: $client.\n";
		        print `stcmsctrlutil.exe -p $port -ds $topic $subscriber $client`;
		}
	}
	close  $slft_fh;
	print `stcmsctrlutil.exe -p $port -dt $topic`;
	return;
}


#==========================
#========== MAIN ==========
#==========================

pod2usage(0) if (@ARGV < 1);

my($port,$topic) = @ARGV;

# If only port given provide menu to allow user to select
$topic = select_topic ($port) if (!defined $topic);

# Now delete the subscribers and topic
delete_topic($port,$topic);






