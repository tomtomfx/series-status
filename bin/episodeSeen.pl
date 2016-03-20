#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Frontier::Client;
use Data::Dumper;
use Sys::Hostname;
use FindBin;
use lib "$FindBin::Bin/../lib";
use betaSeries;

my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $logFile = "";
my $verbose = 0;
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";
my $outputDir = "";


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

	    if ($_ =~ /seenLogFile=(.*\.log)/)
	    {
		    $logFile = $1;
    	}
    	elsif ($_ =~ /betaSeriesKey=(.*)$/)
		{
			$betaSeriesKey = $1;
		}
		elsif ($_ =~ /betaSeriesLogin=(.*)$/)
		{
			$betaSeriesLogin = $1;
		}
		elsif ($_ =~ /betaSeriesPassword=(.*)$/)
		{
			$betaSeriesPassword = $1;
		}
		elsif ($_ =~ /outDirectory=(.*)$/)
		{
			$outputDir = $1;
		}
	}
}

if ($#ARGV < 0) {die "Usage: episodeSeen episode-sXeXX-epId [verbose]\n";}
my $serie = ""; my $episode = ""; my $epId = ""; my $saison = "";
foreach my $arg (@ARGV)
{
	if ($arg eq '-v') {$verbose = 1;}
	elsif ($arg eq '-vv'){$verbose = 2;}
	else {$verbose = 0;}
}
if ($verbose >= 1) {print "$ARGV[0]\n";}
if ($ARGV[0] =~ /(.*)-(.*)-(.*)/)
{
	$serie = $1; $episode = $2; $epId = $3;
	if ($verbose >= 1) {print "$serie - $episode - $epId\n";}
}
if ($serie eq "" or $episode eq "" or $epId eq "") {die "Bad episode info formating: $ARGV[0]\n";}
# Read config file
readConfigFile($verbose);

# Get hostname
my $host = hostname;

if ($verbose >= 1)
{
	# Print BetaSeries infos
	print "BetaSeries login: $betaSeriesLogin\n";
	print "BetaSeries key: $betaSeriesKey\n";	
	print "Output Dir: $outputDir\n";
	print "\n";
}

# open log file
open my $LOG, '>>', $logFile;

# Start writing logs with date and time
my $time = localtime;

# Set episode as seen
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
&betaSeries::setEpisodeSeen($verbose, $token, $betaSeriesKey, $epId);
print $LOG "[$time] $host EpisodeSeen INFO \"$serie - $episode\" watched\n";

# Get file to copy
$serie = lc($serie);
$serie =~ s/_/ /g;
my @extensions = ("mp4", "avi", "mkv");
my $filename = "";
my $fileFound = 0;

for (my $i=0; $i<$#extensions+1; $i++)
{ 
	$filename = "$outputDir\/$serie - $episode\.$extensions[$i]";
	if ($verbose >= 1){print "$filename\n";}
	if (-e $filename){$fileFound = 1;last;}
}

if ($fileFound)
{
	# Get serie/season directory
	if ($episode =~ /s(\d)e\d/) {$saison = $1;}
	my $serieDir = $serie;
	# Specific Marvel's agents of shield
	$serieDir =~ s/s.h.i.e.l.d./shield/i;
	$serieDir = $serieDir." - Saison ".$saison;
	$serieDir =~ s/^(\w)/\U$1/;
	if($verbose >= 1){print "$outputDir\/$serieDir\/.\n";}
	if (!-d "$outputDir\/$serieDir\/"){mkdir "$outputDir\/$serieDir\/";}
	
	# Copy file to its serie/season directory
	my $commandVideo = "mv \"$filename\" \"$outputDir\/$serieDir\"\/.";
	my $commandSrt = "mv \"$outputDir\/$serie - $episode.srt\" \"$outputDir\/$serieDir\"\/.";
	#my $commandMeta = "mv \"$outputDir\/$serie - $episode.metathumb\" \"$outputDir\/$serieDir\"\/.";
	#my $commandXml = "mv \"$outputDir\/$serie - $episode.xml\" \"$outputDir\/$serieDir\"\/.";
	#my $commandBackdrop = "mv \"$outputDir\/.$serie - $episode.backdrop\" \"$outputDir\/$serieDir\"\/";
	if($verbose >= 1){print "$commandMp4\n";}
	system($commandVideo);
	system($commandSrt);
	#system($commandMeta);
	#system($commandXml);
	#system($commandBackdrop);
}
close $LOG;
