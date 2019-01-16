#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use betaSeries;

my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $downloadsListFile = "";
my $verbose = 0;
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";

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

	    if ($_ =~ /downloadsListFile=(.*\.list)/)
	    {
		    $downloadsListFile = $1;
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
	}
}

foreach my $arg (@ARGV)
{
	if ($arg eq '-v') {$verbose = 1;}
	elsif ($arg eq '-vv'){$verbose = 2;}
	else {$verbose = 0;}
}

# Read config file
readConfigFile($verbose);

if ($verbose >= 1)
{
	# Print BetaSeries infos
	print "Downloads file list: $downloadsListFile\n";
	print "BetaSeries login: $betaSeriesLogin\n";
	print "BetaSeries key: $betaSeriesKey\n";	
	print "\n";
}

# open log file
open my $LOG, '>', $downloadsListFile or die "Cannot open output file: $downloadsListFile\n";

# Get episodes to download
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my @episodeToDownload = &betaSeries::getEpisodeToDownload($verbose, $token, $betaSeriesKey);
foreach my $ep (@episodeToDownload)
{
	if ($ep =~ /(.*) - (.*) - /)
	{
		my $serie = $1; my $episode = $2;
		print $LOG "$serie - $episode\n";
	}
}

print $LOG "\n";
close $LOG;
