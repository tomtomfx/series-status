#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Mojo::UserAgent;
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
my $outputDir = "";

# Database variables
my $serieDsn = "";
my $seriesDatabasePath = "";
my $driver = "SQLite"; 
my $userid = "";
my $password = "";
my $useKodi = 0;
my $kodiIpAddress = "";


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
	    if ($_ =~ /seenLogFile=(.*\.log)/){$logFile = $1;}
    	elsif ($_ =~ /betaSeriesKey=(.*)$/){$betaSeriesKey = $1;}
		elsif ($_ =~ /betaSeriesLogin=(.*)$/){$betaSeriesLogin = $1;}
		elsif ($_ =~ /betaSeriesPassword=(.*)$/){$betaSeriesPassword = $1;}
		elsif ($_ =~ /outDirectory=(.*)$/){$outputDir = $1;}
		elsif ($_ =~ /databasePath=(.*)$/){$seriesDatabasePath = $1;}
		elsif ($_ =~ /useKodi=(.*)$/){$useKodi = $1;}
		elsif ($_ =~ /kodiIpAddress=(.*)$/){$kodiIpAddress = $1;}
	}
}

sub sendRequest
{
	my $request = $_[0];
	my $ua = Mojo::UserAgent->new(); 
	my $tx = $ua->get($request);
	if ($tx->success)
	{
		my $ret = $tx->res->json;
		return $ret;
	}
	elsif (my $err = $tx->error)
	{
		print "Error: ".$err->{message}."\n";
		return 0;
	}
}

if ($#ARGV < 0) {die "Usage: episodeSeen episode-sXeXX-epId [verbose]\n";}
my $serie = ""; my $episode = ""; my $epId = ""; my $season = 0; my $epNumber = 0;
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
	$serie =~ s/_/ /ig;
	$serie =~ s/\*/&/ig;
	if ($episode =~ /s(\d+)e(\d+)/i){$season = $1; $epNumber = $2;}
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
	print "Serie database: $seriesDatabasePath\n";
	print "\n";
}

# open log file
open my $LOG, '>>', $logFile;

# Start writing logs with date and time
my $time = localtime;

#########################################################################################
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
# Mark episode as watched in Kodi
# Connect to Kodi
if ($useKodi == 1)
{
	my $port = "8080";
	my $kodiHost = "http:\/\/".$kodiIpAddress.":".$port."\/jsonrpc";
	my $serieKodi = $serie;

	# Specific naming
	$serieKodi =~ s/marvel//ig;

	# Get TV show ID
	my $tvshowid = 0;
	my $method = 'VideoLibrary.GetTVShows';
	my $request = $kodiHost."?request={\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"".$method."\"}";
	if ($verbose >= 1) {print Dumper ($request);}
	my $result = sendRequest($request);
	my @tvshows = @{$result->{'result'}->{'tvshows'}};
	foreach my $show (@tvshows)
	{
		if ($show->{'label'} =~ /$serieKodi/i)
		{
			$tvshowid = $show->{'tvshowid'};
			last;
		}
	}
	if ($verbose >= 1) {print ("TV show ID: ".$tvshowid."\n");}
	
	if ($tvshowid != 0)
	{
		# Get episode ID
		my $epId = 0;
		$method = 'VideoLibrary.GetEpisodes';
		my $params = "\", \"params\": {\"tvshowid\":".$tvshowid.", \"season\":".$season.", \"properties\": [\"season\", \"episode\"]}";
		$request = $kodiHost."?request={\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"".$method.$params."}";
		if ($verbose >= 1) {print Dumper ($request);}
		$result = sendRequest($request);
		if (defined $result->{'result'}->{'episodes'})
		{
			my @episodes = @{$result->{'result'}->{'episodes'}};
			foreach my $episode (@episodes)
			{
				if ($episode->{'season'} == $season and $episode->{'episode'} == $epNumber)
				{
					$epId = $episode->{'episodeid'};
					last;
				}
			}
			if ($verbose >= 1) {print ("Episode ID: ".$epId."\n");}
			if ($epId != 0)
			{
				$method = 'VideoLibrary.SetEpisodeDetails';
				$params = "\", \"params\": {\"episodeid\":".$epId.", \"playcount\": 1}";
				$request = $kodiHost."?request={\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"".$method.$params."}";
				if ($verbose >= 1) {print Dumper ($request);}
				$result = sendRequest($request);
				if ($verbose >= 1) {print ("Set as seen: ".$result->{'result'}."\n");}
			}
		}
	}
}
close $LOG;
