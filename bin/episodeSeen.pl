#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Frontier::Client;
use Data::Dumper;
use Sys::Hostname;
use DBI;
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

# Database variables
my $tabletDatabasePath = "";
my $serieDsn = "";
my $seriesDatabasePath = "";
my $dsn = "";
my $driver = "SQLite"; 
my $userid = "";
my $password = "";

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
		elsif ($_ =~ /tabletDatabasePath=(.*)$/)
		{
			$tabletDatabasePath = $1;
		}
		elsif ($_ =~ /databasePath=(.*)$/)
		{
			$seriesDatabasePath = $1;
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

my $episodeId = "\'$serie - $episode\'";

#########################################################################################
# Remove episode from the series database
# Connect to database
$serieDsn = "DBI:$driver:dbname=$seriesDatabasePath";
my $serieDbh = DBI->connect($serieDsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
# Remove episode
if ($verbose >= 1){print "$episodeId\n";}
$serieDbh->do("DELETE FROM unseenEpisodes WHERE id=($episodeId)");
$serieDbh->disconnect();

#########################################################################################
# Remove episode from the tablet database
# Connect to database
$dsn = "DBI:$driver:dbname=$tabletDatabasePath";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
# Remove episode
if ($verbose >= 1){print "$episodeId\n";}
$dbh->do("DELETE FROM Episodes WHERE id=($episodeId)");
$dbh->disconnect();

close $LOG;
