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

my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
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

if ($#ARGV < 0) {die "Usage: archiveSerie \"serieName\" [verbose]\n";}
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
if ($serie eq "") {die "Usage: archiveSerie \"serieName\" [verbose]\n";}
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
	print "Show to archive: $serie\n";
	print "\n";
}

# open log file
open my $LOG, '>>', $logFile;

# Get serie out of URL formatting
# $serie =~ s/_/ /ig;

# Connection to betaseries.com
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my $serieId = &betaSeries::searchSerie($verbose, $token, $betaSeriesKey, $serie);
print Dumper $serieId;
if ($serieId != 0)
{
	# Add serie to the followed shows on betaseries
	&betaSeries::archiveShow($verbose, $token, $betaSeriesKey, $serieId);

	#########################################################################################
	# Mark all episodes in the series database as archived
	# Connect to database
	$serieDsn = "DBI:$driver:dbname=$seriesDatabasePath";
	my $serieDbh = DBI->connect($serieDsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
	# Query to get all episodes from a show
	my $query = "SELECT * FROM unseenEpisodes WHERE Show=?";
	if ($verbose >= 2){print "$query\n";}
	my $sth = $serieDbh->prepare($query);
	$sth->execute("$serie");
	while(my $episode = $sth->fetchrow_hashref)
	{
		if ($verbose >= 1){print ("$episode->{'Id'}\n");}
		$serieDbh->do("UPDATE unseenEpisodes SET Archived=\'TRUE\' WHERE Id=\'$episode->{'Id'}\'");
	}
	$sth->finish();
	$serieDbh->disconnect();
}

#print $LOG "\n";
close $LOG;
