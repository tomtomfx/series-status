#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Frontier::Client;
use Data::Dumper;
use Sys::Hostname;
use Rarbg::torrentapi;
use DBI;
use FindBin;
use lib "$FindBin::Bin/../lib";
use betaSeries;
use tvdb;

my $config = "scriptsDir\/bin\/config";
my $logFile = "";
my $verbose = 0;
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";
my $serieDatabasePath = "";
my $tvdbApiKey = "";
my $tvdbUser = "";
my $tvdbUserKey = "";
my $torrentUrl = "";
my $bannersPath = "";
my $backgroundsPath = "";

# Database
my $driver = "SQLite"; 
my $dsn = "";
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
	    if ($_ =~ /unseenLogFile=(.*\.log)/){$logFile = $1;}
		elsif ($_ =~ /databasePath=(.*)$/){$serieDatabasePath = $1;}
		elsif ($_ =~ /bannersPath=(.*)$/){$bannersPath = $1;}
		elsif ($_ =~ /backgroundsPath=(.*)$/){$backgroundsPath = $1;}
    	elsif ($_ =~ /betaSeriesKey=(.*)$/){$betaSeriesKey = $1;}
		elsif ($_ =~ /betaSeriesLogin=(.*)$/){$betaSeriesLogin = $1;}
		elsif ($_ =~ /betaSeriesPassword=(.*)$/){$betaSeriesPassword = $1;}
		elsif ($_ =~ /tvdbApiKey=(.*)$/){$tvdbApiKey = $1;}
		elsif ($_ =~ /tvdbUser=(.*)$/){$tvdbUser = $1;}
		elsif ($_ =~ /tvdbUserKey=(.*)$/){$tvdbUserKey = $1;}
	}
}

sub getTorrentUrl
{
	my ($serie, $episodes, $ua,$verbose) = @_;
	# Remove (year)
	if ($serie =~ /(.*) \(\d{4}\)/){$serie = $1;}
	# Specific for marvel's agent of shield
	$serie =~ s/\'s/s/i;
	# Specific for Mr. Robot
	$serie =~ s/Mr\./Mr/i;
	
	my $kickass = "";
	my $t1337 = "";
	my $pirate = "";
	my $pirate2 = "";
	my $rarbg = "";
	
	$serie =~ s/ /+/g;
	
	# Get torrent URL from rarbg
	if ($verbose >= 1) {print "Looking on Rarbg\n";}
	my $tapi = Rarbg::torrentapi->new();
	sleep(5);
	my $search = $tapi->search({search_string => "$serie $episodes", category => '18;41', min_seeders => 20});
	if (ref $search ne "ARRAY")
	{
		sleep(5);
		$search = $tapi->search({search_string => "$serie $episodes", category => '18;41', min_seeders => 20});
	}
	if (ref $search eq "ARRAY")
	{
		foreach my $res (@{$search})
		{
			my $title = $res->{'title'};
			if ($title =~ /1080/){next;}
			$rarbg = $res->{'download'};
		}
	}
	# Get torrent URL from 1337.to
	if ($verbose >= 1) {print "http://1337x.to/search/$serie+$episodes+x264/1/\n";}
	my $response = $ua->get("http://1337x.to/search/$serie+$episodes+x264/1/");
	my @x1337 = split("\n", $response->decoded_content);
	foreach (@x1337)
	{
		if ($_ =~ /<a href=\"(\/torrent\/\d*\/.*\/)\">/)
		{
			$t1337 = "http:\/\/1337x.to".$1;
			last;
		}
	}
	
	# Get torrent URL from thepiratebay
	if ($verbose >= 1) {print "https://tpb.proxyduck.info/search.php?q=$serie+$episodes+x26*&page=0&orderby=99\n";}
	$response = $ua->get("https://tpb.proxyduck.info/search.php?q=$serie+$episodes+x26*&page=0&orderby=99");
	my @pirate = split("\n", $response->decoded_content);
	foreach (@pirate)
	{
		if ($_ =~ /<a href=\"(magnet:.*)\" title=\"Download this torrent using magnet\"/)
		{
			$pirate = $1;
			last;
		}
	}
	
	# Get torrent URL from thehiddenbay
	# if ($verbose >= 1) {print "https://thehiddenbay.info/search/$serie+$episodes+x26*/0/99/0\n";}
	# $response = $ua->get("https://thehiddenbay.info/search/$serie+$episodes+x26*/0/99/0");
	# my @pirate2 = split("\n", $response->decoded_content);
	# foreach (@pirate2)
	# {
		# if ($_ =~ /<a href=\"(magnet:.*)\" title=\"Download this torrent using magnet\"/)
		# {
			# $pirate2 = $1;
			# last;
		# }
	# }
	
	# Get torrent URL from kickass
	if ($verbose >= 1) {print "http://kickass.cd/search.php?q=$serie+$episodes+x264\n";}
	$response = $ua->get("http://kickass.cd/search.php?q=$serie+$episodes+x264");
	my @kickass = split("\n", $response->decoded_content);
	foreach (@kickass)
	{
		if ($_ =~ /<a href=\"(\/.*)\" class=\"cellMainLink\">/)
		{
			$kickass = "http:\/\/kickass.cd".$1;
			last;
		}
	}
	
	if ($verbose >= 1) {print ("kickass = $kickass\n1337 = $t1337\nPirateBay = $pirate\nHiddenBay = $pirate2\nrarbg = $rarbg");}

	if ($rarbg ne "" && $ua->get($rarbg) eq "") {$rarbg = "";}
	if ($t1337 ne "" && $ua->get($t1337) eq "") {$t1337 = "";}
	if ($kickass ne "" && $ua->get($kickass) eq "") {$kickass = "";}
	if ($pirate ne "" && $ua->get($pirate) eq "") {$pirate = "";}
	if ($pirate2 ne "" && $ua->get($pirate2) eq "") {$pirate2 = "";}
	
	if ($rarbg ne ""){return $rarbg;}
	elsif ($t1337 ne "")
	{
		my $res = $ua->get($t1337);
		my @url = split("\n", $res->decoded_content());
		foreach (@url)
		{
			# print Dumper($_);
			if ($_ =~ /href=\"(magnet:.*announce)\" onclick=\"/) 
			{
				if ($verbose >= 1) {print "$1\n";}
				return $1;
			}
		}
	}
	elsif ($pirate ne ""){return $pirate;}
	elsif ($pirate2 ne ""){return $pirate2;}
	elsif ($kickass ne "")
	{
		my $res = $ua->get($kickass);
		my @url = split("\n", $res->decoded_content());
		foreach (@url)
		{
			if ($_ =~ /href=\"(magnet:.*)\"><i class=\"ka ka-magnet\"><\/i><\/a>/) 
			{
				if ($verbose >= 1) {print "$1\n";}
				return $1;
			}
		}
	}
}
sub does_table_exist 
{
    my ($dbh, $table_name) = @_;
	my $sth = $dbh->prepare("SELECT name FROM sqlite_master WHERE type=\'table\' AND name=\'$table_name\';");
    $sth->execute();
	my @info = $sth->fetchrow_array;
    my $exists = scalar @info;
	return $exists;
}

##### Program start #####
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
	print "BetaSeries login: $betaSeriesLogin\n";
	print "BetaSeries key: $betaSeriesKey\n";
	print "tvdbUser login: $tvdbUser\n";
	print "tvdbApiKey key: $tvdbApiKey\n";
	print "Banners path: $bannersPath\n";
	print "Backgrounds path: $backgroundsPath\n";	
	print "\n";
}

# open log file
open my $LOG, '>>', $logFile;

# Get hostname
my $host = hostname;

#########################################################################################
# Open Database connection
$dsn = "DBI:$driver:dbname=$serieDatabasePath";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Database opened successfully\n";}	
my $exists = does_table_exist($dbh, "unseenEpisodes");
if ($exists == 0)
{
	if ($verbose >= 1){print ("No table \"unseenEpisodes\" available in this database. Creating...\n");}
	$dbh->do("DROP TABLE IF EXISTS unseenEpisodes");
	$dbh->do("CREATE TABLE unseenEpisodes(Id TEXT PRIMARY KEY, Show TEXT, Title TEXT, IdBetaseries TEXT, Status TEXT, Location TEXT, Archived TEXT, Tablet TEXT, CopyRequested TEXT, IsOnTablet TEXT)");
}

# Create user agent for https
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
$ua->agent('Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0 Iceweasel/31.3.0');

# Get episodes to download
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my @episodeToDownload = &betaSeries::getEpisodeToDownload($verbose, $token, $betaSeriesKey);
foreach my $ep (@episodeToDownload)
{
	my $time = localtime;
	my $status = "Download failed";
	if ($ep =~ /(.*) - (.*) - (.*) - (.*)/)
	{
		my @torrentUrl;
		my $result = 0;
		my $serie = $1; my $episode = $2; my $title = $3; my $id = $4;
		$title =~ s/'//g;
		$serie =~ s/'//g;
		
		# Get TVDB authentication token
		my $tvdbToken = &tvdb::authentication($verbose, $tvdbApiKey, $tvdbUser, $tvdbUserKey);
		# Get TVDB show ID
		my $tvdbShowId = &betaSeries::getShowTvdbIdFromEpisodeId($verbose, $token, $betaSeriesKey, $id);
		# Get show banner if doesn't exists
		my $banner = "$bannersPath\/$serie.jpg";
		unless (-e $banner)
		{
			if ($verbose >=1) {print "Banner $banner does not exist\n";}
			my $tvdbBanner = &tvdb::getShowImage($verbose, $tvdbToken, $tvdbShowId, "series");
			if ($verbose >=1) {print "$tvdbBanner\n";}
			getstore($tvdbBanner, $banner);
		}
		# Get show background if doesn't exists
		my $background = "$backgroundsPath\/$serie.jpg";
		unless (-e $background)
		{
			if ($verbose >=1) {print "Background $background does not exist\n";}
			my $tvdbBackground = &tvdb::getShowImage($verbose, $tvdbToken, $tvdbShowId, "fanart");
			if ($verbose >=1) {print "$tvdbBackground\n";}
			getstore($tvdbBackground, $background);
		}
		
		# Get Torrent for this episode
		my $searchSerie = $serie;
		$searchSerie =~ s/&/and/ig;
		push (@torrentUrl, getTorrentUrl($searchSerie, $episode, $ua,$verbose));
		if ($torrentUrl[0] eq "") {$result = 1;}
		if ($verbose >= 1) {print "$torrentUrl[0]\n";}
		print $LOG "[$time] $host Download INFO \"$serie - $episode\" $torrentUrl[0]\n";
		if ($torrentUrl[0] ne "")
		{
			my $xmlrpc = Frontier::Client->new('url' => 'http://192.168.1.5/RPC2');
			$result = $xmlrpc->call("load.start", "", @torrentUrl);
		}
		if ($result eq "0"){$status = "Download launched";}
		
		# Add unseen episode to the serie database
		# Query to check if the episode already exists
		my $query = "SELECT COUNT(*) FROM unseenEpisodes WHERE Id=?";
		if ($verbose >= 2){print "$query\n";}
		my $sth = $dbh->prepare($query);
		$sth->execute("$serie - $episode");
		if ($sth->fetch()->[0]) 
		{
			if ($verbose >= 1){print "$serie - $episode already exists\n";}
			$dbh->do("UPDATE unseenEpisodes SET Status=\'$status\' WHERE Id=\'$serie - $episode\'");
		}
		else
		{
			# Add episode
			my $episodeInfos = "\'$serie - $episode\', \'$serie\', \'$title\', \'$id\', \'$status\', \'\', \'\', \'\', \'\', \'\'";
			if ($verbose >= 1){print "$episodeInfos\n";}
			$dbh->do("INSERT INTO unseenEpisodes VALUES($episodeInfos)");
		}
		$sth->finish();
		
		if ($result eq "0") {print $LOG "[$time] $host Download INFO \"$serie - $episode\" --> OK\n";}
		else {print $LOG "[$time] $host Download ERROR \"$serie - $episode\" --> Failed\n"; next;}
		
		sleep(20);
	}
}

#print $LOG "\n";
close $LOG;
