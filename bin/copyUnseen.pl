#!/usr/bin/perl

use strict;
use warnings;
use Sys::Hostname;
use File::Remove 'remove';
use File::Copy;

my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $inputDir = "";
my $outputDir = "";
my $logFile = "";
my $verbose = 0;

# Read config file 
sub readConfigFile
{
	my $verbose = $_[0];
	my $readingShows = 0;
	# Open config file
	if ($verbose >= 1) {print "Read config file\n"};
	open my $CONF, '<', $config or die "Cannot open $config";
	my @conf = <$CONF>;
	close $CONF;
	foreach (@conf)
	{
	    chomp($_);
	    if ($_ =~ /^#/) {next;}			
	    if ($_ =~ /shows/) 
    	{
		    last;
		}
	    if ($_ =~ /copyUnseenLogFile=(.*\.log)/)
	    {
		    $logFile = $1;
    	}
		elsif ($_ =~ /outDirectory=(.*)$/)
		{
			$outputDir = $1;
		}
		elsif ($_ =~ /nfsDirectory=(.*)$/)
		{
			$inputDir = $1;
		}
	}
}

foreach my $arg (@ARGV)
{
	if ($arg eq '-v') {$verbose = 1;}
	elsif ($arg eq '-vv'){$verbose = 2;}
	elsif ($arg eq '-vvv'){$verbose = 3;}
	else {$verbose = 0;}
}
# Read config file
readConfigFile($verbose);
if ($verbose >= 2)
{
	# Print available shows
	print "Input: $inputDir\n";
	print "Output: $outputDir\n";
	print "Log: $logFile\n";
	print "\n";
}
# open log file
open my $LOG, '>>', $logFile or die "Cannot open $logFile";

# Get hostname
my $host = hostname;

# Get date and time for log info
my $time = localtime;

################################################
# Delete episodes already watched
if ($verbose >= 1) {print "##### Delete viewed episodes #####\n";}
# open nfs directory
opendir(DL, $outputDir) or die "Cannot open $outputDir";;
my @outDir = readdir(DL);
close DL;

foreach my $file (@outDir)
{
	if (-d "$outputDir\/$file" || -e "$inputDir\/$file") {next;}
	elsif ($file !~ /\.mp4$/ && $file !~ /\.avi$/) {next;}
	else
	{
		$file =~ s/\.mp4//;
		$file =~ s/\.avi//;		
		remove( "$outputDir\/$file.*");
		print $LOG "[$time] $host CopyUnseen INFO $file seen\n";
	}
}
################################################

################################################
# Check non-watched episodes and copy if new
# open input directory
opendir(DL, $inputDir) or die "Cannot open $inputDir";
my @inDir = readdir(DL);
close DL;

foreach my $file (@inDir)
{
	my $fileFound = 0;
	if (-d "$inputDir\/$file" || -e "$outputDir\/$file") {next;}
	if ($file =~ /\.srt$/ || $file =~ /\.xml$/ || $file =~ /\.metathumb$/ || $file =~ /\.jpg$/ || $file =~ /^\./) {next;}
	else
	{
		copy("$inputDir\/$file","$outputDir\/$file") or die "Copy failed: $!";
		$file =~ s/\.mp4//;
		$file =~ s/\.avi//;		
		copy("$inputDir\/$file.srt","$outputDir\/$file.srt") or die "Copy failed: $!";
		print $LOG "[$time] $host CopyUnseen INFO $file downloaded\n";
	}
}
################################################

close $LOG;
