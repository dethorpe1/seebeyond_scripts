#! /usr/bin/perl  -w

# See usage() method for synopsis.

use strict;
use Getopt::Std;
use File::Basename;
use Text::Wrap;

sub usage()
{
	print <<END;

Description
-----------
Script to split a log file, or set of files,  into seperate 
files for each thread and display loglines for a specific class 
or all classes.

If a wildcard is specified in the logfile name then lines from all
files matching are combined into the split output files.

If a thread is specified on the command line then a log file
for that thread/class only is generated.

Usage
-----
ican_log_threads.pl -l <log file> [-t <thread> -c <class> -f -s]
    -l <log file>: log file to split
    -t <thread>  : thread to split, optional, default is all threads
    -c <class>   : class to filter, optional, default is all classes
    -f           : Filter output ON, removes lines matching filter list
                   in FilterLine() routine, optional, default is OFF
    -s           : Strip matched class field, only if -c option used.
                   (Useful to make log more readable)
    -p           : Pretty. Will wrap long log lines and align at end 
                   of log type  field

END
}

# routine to test a line against a list of patterns to filter out of the log file
# returns 1 if the line shound be filtered, 0 if not
sub FilterLine($)
{
	# Add any patterns for lines to remove to this array
	my (@filterList) = ('Normal \(non-correlating\) Collab');

	my($Line) = $_[0];
	my($retCode) = 0;
	my($filter);


	foreach $filter (@filterList)
	{
		if ($Line =~ m/$filter/ )
		{
			$retCode = 1;
			last;
		}
	}	
	return $retCode;
}

############################
# START OF MAIN PROCESSING #
############################

my ($reqThread, $logfile, $reqClass,%ThreadFile,%opts);
my $bDontFilter = 1;
my $bPretty = 0;
my $bStripKeys = 0;
my $lastThread = -1;
my $textWrapPad = "                             ";

use constant THREAD_INDEX => 3;
use constant JMS_THREAD_INDEX => 5;
use constant CLASS_INDEX => 4;
use constant JMS_CLASS_INDEX => 6;

$Text::Wrap::columns=140;
$Text::Wrap::hugh='overflow';

getopts ('l:t:c:fsp',\%opts);

if (defined($opts{"l"}) && $opts {"l"} ne "1") {
	$logfile=$opts{"l"}; 
} else {
	usage(); die "\n ERROR: -l option missing or has no argument";
}
$reqThread=$opts{"t"} if (defined($opts{"t"}));
$reqClass=$opts{"c"}  if (defined($opts{"c"}));
$bDontFilter = 0      if (defined($opts{"f"})); 
$bStripKeys = 1       if (defined($opts{"s"})); 
$bPretty = 1          if (defined($opts{"p"})); 

$|=1; # Turn on auto flush for stdout

my ($basefile) = basename($logfile);
chomp($basefile);

if (defined ($reqThread)) { print "Generating log file for thread $reqThread, in log file $logfile...\n"; } else
			  { print "Generating log file for every thread in $logfile...\n" ;}
if (defined ($reqClass))  { print "Generating log file for class $reqClass, in log file $logfile...\n"; } else
			  { print "Generating log file for every class in $logfile...\n" ;}
if ($bDontFilter) { print "Filter is OFF\n"; } else { print "Filter is ON\n";}

# if wildcards are in name then combine all matched logfile into one set of output files
while (my $file = glob($logfile)) {
	open (FILE_IN, "<$file") || die "ERROR: Unable to open file $logfile";
	print (" ## Scaning file: $file....\n" );
	while (my $line = <FILE_IN>)
	{
		chomp ($line);
		my @fields=split (/ +/,$line);
		my $thread = $fields[THREAD_INDEX];
		my $class = $fields[CLASS_INDEX];
		my $date = $fields[0];

		# special case for Odd JMS threads which have differnet thread field format (JMS Async S<thread>)
		if (defined ($thread) && $thread eq "[JMS") {
			$thread = $fields[JMS_THREAD_INDEX];
			$class = $fields[JMS_CLASS_INDEX];
		}

		# check thread and date are valid
		if ( defined ($thread) && 
			 $date =~ m/[0-9]{4}-[0-9]{2}-[0-9]{2}/ && 
			 $thread =~ m/(Thread-|S)([0-9]+)/ ) {

			$thread = $2; # get actual thread number from field match

			# output line to file for the specific thread/class. If the user has specified a
			# thread on the command line then only output logs for that thread
			# Also checks if line is in filter list, and if so dosn't output it

			if ((!defined($reqThread) || $reqThread == $thread ) &&
				(!defined($reqClass) || $class =~ m/$reqClass/i ) ) {

				if ($bDontFilter || !FilterLine($line))
				{
					# see if we have allready started a log for this thread
					my $fileKey = $thread;
					$fileKey .= "~${reqClass}" if (defined($reqClass));

					unless (defined $ThreadFile{$thread})
					{
						# We haven't started a log for this thread so start a new one.
						#$ThreadFile{$thread} = "THREAD" . $thread;
						print "Found log entries for thread: $fileKey\n";
						open ( $ThreadFile{$thread}, ">$basefile.$fileKey.log" ) || 
							die " ERROR: Unable to open thread output file: $basefile.$fileKey.log";
					}
					# remove the matched class and thread filter key fields if enabled. makes for easier viewing
					# (theres sometimes an empty field after the class field so remove that as well)
					$line =~ s/ +\Q${class}\E ?\[?\]?// if ($bStripKeys == 1 && defined $reqClass);
					$line =~ s/ +\[(Thread-|JMS Async S)$thread\]// if ($bStripKeys == 1 && defined $reqThread);

					# wrap and pad lines at the class field start for easier viewing
					$line = wrap("",$textWrapPad,"$line") if $bPretty;

					# write the line to the threads log file
					print ( { $ThreadFile{$thread} } "$line\n"); 
					$lastThread = $thread;
				}
			} 
			else {
				# reset last thread as we have now skipped lines for unwanted threads/classes
				$lastThread = -1;
			}

		}
		elsif ($lastThread != -1 ) {
			# Log to last unfiltered file written 
			# as its an unknow format so most likly belongs to that e.g stack dump
			print ({ $ThreadFile{$lastThread} } "$line\n"); 
		}
	}
	close (FILE_IN);
}



