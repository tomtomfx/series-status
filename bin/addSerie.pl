#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use Sys::Hostname;
use DBI;
use FindBin;
use lib "$FindBin::Bin/../lib";
use betaSeries;

my $config = "scriptsDir\/bin\/config";
my $logFile = "";
my $verbose = 0;
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";

my $driver = "SQLite"; 
my $userid = "";
my $password = "";
my $serieDsn = "";
my $seriesDatabasePath = "";

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
	    if ($_ =~ /addSerieLogFile=(.*\.log)/){$logFile = $1;}
    	elsif ($_ =~ /betaSeriesKey=(.*)$/){$betaSeriesKey = $1;}
		elsif ($_ =~ /betaSeriesLogin=(.*)$/){$betaSeriesLogin = $1;}
		elsif ($_ =~ /betaSeriesPassword=(.*)$/){$betaSeriesPassword = $1;}
		elsif ($_ =~ /databasePath=(.*)$/){$seriesDatabasePath = $1;}
	}
}

sub sendRequest
{
	my $ua = $_[0]; my $req = $_[1];
	my $resp = $ua->request($req);
	if ($resp->is_success) 
	{
		my $message = $resp->decoded_content;
		return $message;
	}
	else 
	{
		print "HTTP POST error code: ", $resp->code, "\n";
		print "HTTP POST error message: ", $resp->message, "\n";
		return 0;
	}
}

if ($#ARGV < 0) {die "Usage: addSerie \"serieName\" [verbose]\n";}
foreach my $arg (@ARGV)
{
	if ($arg eq '-v') {$verbose = 1;}
	elsif ($arg eq '-vv'){$verbose = 2;}
	else {$verbose = 0;}
}
my $serie = "";
if ($verbose >= 1) {print "$ARGV[0]\n";}
if ($ARGV[0] =~ /(.*)/)
{
	$serie = $1;
	if ($verbose >= 1) {print "$serie\n";}
}
if ($serie eq "") {die "Usage: addSerie \"serieName\" [verbose]\n";}
# Read config file
readConfigFile($verbose);

# Get hostname
my $host = hostname;
if ($verbose >= 1)
{
	# Print BetaSeries infos
	print "BetaSeries login: $betaSeriesLogin\n";
	print "BetaSeries key: $betaSeriesKey\n";	
	print "Log file: $logFile\n";
	print "\n";
}

# open log file
open my $LOG, '>>', $logFile;

# Connection to betaseries.com
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my ($serieId, $showName) = &betaSeries::searchSerie($verbose, $token, $betaSeriesKey, $serie);
if ($serieId != 0)
{
	# Add serie to the followed shows on betaseries
	&betaSeries::addShow($verbose, $token, $betaSeriesKey, $serieId);
	
	# check if episodes exist in the database (show previously archived)
	# Connect to database
	$serieDsn = "DBI:$driver:dbname=$seriesDatabasePath";
	my $serieDbh = DBI->connect($serieDsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
	# Query to get all episodes from the show
	my $query = "SELECT * FROM unseenEpisodes WHERE Show=?";
	if ($verbose >= 2){print "$query\n";}
	my $sth = $serieDbh->prepare($query);
	$sth->execute("$showName");
	while(my $episode = $sth->fetchrow_hashref)
	{
		if ($verbose >= 1){print ("$episode->{'Id'}\n");}
		$serieDbh->do("UPDATE unseenEpisodes SET Archived=\'FALSE\' WHERE Id=\'$episode->{'Id'}\'");
	}
	$sth->finish();
	$serieDbh->disconnect();	
	
	# Add the serie to the config file
	# Ensure it is lower case
	$serie = lc($serie);
	# Read all config file
	open my $CONF, '<', $config or die "Cannot open $config";
	my @conf = <$CONF>;
	close $CONF;
	
	# Check if serie is already in config file
	my $alreadyThere = 0;
	foreach my $line (@conf)
	{
		if ($line eq "$serie,\n"){$alreadyThere = 1;}
	}
	if ($alreadyThere == 0)
	{
		# Re-write the config file adding the new serie
		open my $CONF, '>', $config or die "Cannot open $config";
		foreach my $line (@conf)
		{
			if ($line =~ /\/shows/){last;}
			print $CONF "$line";
		}
		close $CONF;
	}
}

#print $LOG "\n";
close $LOG;
