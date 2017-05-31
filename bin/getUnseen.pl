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
my $torrentUrl = "";

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

	    if ($_ =~ /unseenLogFile=(.*\.log)/)
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
	
	$serie =~ s/ /+/g;
	
	# Get torrent URL from 1337.pl
	if ($verbose >= 1) {print "http://1337x.pl/search/$serie+$episodes+x264/1/\n";}
	my $response = $ua->get("http://1337x.pl/search/$serie+$episodes+x264/1/");
	my @x1337 = split("\n", $response->decoded_content);
	foreach (@x1337)
	{
		if ($_ =~ /<strong><a href=\"(\/torrent\/\d*\/.*\/)\"><b>/)
		{
			$t1337 = "http:\/\/1337x.pl".$1;
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
	if ($verbose >= 1) {print "https://thehiddenbay.info/search/$serie+$episodes+x26*/0/99/0\n";}
	$response = $ua->get("https://thehiddenbay.info/search/$serie+$episodes+x26*/0/99/0");
	my @pirate2 = split("\n", $response->decoded_content);
	foreach (@pirate2)
	{
		if ($_ =~ /<a href=\"(magnet:.*)\" title=\"Download this torrent using magnet\"/)
		{
			$pirate2 = $1;
			last;
		}
	}
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
	
	if ($verbose >= 1) {print ("kickass = $kickass\n1337 = $t1337\nPirateBay = $pirate\nHiddenBay = $pirate2\n");}

	if ($kickass ne "" && $ua->get($kickass) eq "") {$kickass = "";}
	if ($t1337 ne "" && $ua->get($t1337) eq "") {$t1337 = "";}
	if ($pirate ne "" && $ua->get($pirate) eq "") {$pirate = "";}
	if ($pirate2 ne "" && $ua->get($pirate2) eq "") {$pirate2 = "";}
	
	if ($pirate ne "")
	{
		return $pirate;
	}
	if ($pirate2 ne "")
	{
		return $pirate2;
	}
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
	elsif ($t1337 ne "")
	{
		my $res = $ua->get($t1337);
		my @url = split("\n", $res->decoded_content());
		foreach (@url)
		{
			# print Dumper($_);
			if ($_ =~ /id=\"magnetdl\" href=\"(magnet:.*announce)\" onclick=\"/) 
			{
				if ($verbose >= 1) {print "$1\n";}
				return $1;
			}
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
	print "BetaSeries login: $betaSeriesLogin\n";
	print "BetaSeries key: $betaSeriesKey\n";	
	print "\n";
}

# open log file
open my $LOG, '>>', $logFile;

# Get hostname
my $host = hostname;

# Create user agent for https
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
$ua->agent('Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0 Iceweasel/31.3.0');

# Get episodes to download
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my @episodeToDownload = &betaSeries::getEpisodeToDownload($verbose, $token, $betaSeriesKey);
foreach my $ep (@episodeToDownload)
{
	my $time = localtime;

	if ($ep =~ /(.*) - (.*) - /)
	{
		my @torrentUrl;
		my $result = 0;
		my $serie = $1; my $episode = $2;
		push (@torrentUrl, getTorrentUrl($serie, $episode, $ua,$verbose));
		if ($torrentUrl[0] eq "") {$result = 1;}
		if ($verbose >= 1) {print "$torrentUrl[0]\n";}
		print $LOG "[$time] $host Download INFO \"$serie - $episode\" $torrentUrl[0]\n";
		if ($torrentUrl[0] ne "")
		{
			my $xmlrpc = Frontier::Client->new('url' => 'http://192.168.1.5/RPC2');
			$result = $xmlrpc->call("load_start", @torrentUrl);
		}
		if ($result eq "0") {print $LOG "[$time] $host Download INFO \"$serie - $episode\" --> OK\n";}
		else {print $LOG "[$time] $host Download ERROR \"$serie - $episode\" --> Failed\n"; next;}
		
		sleep(20);
	}
}

#print $LOG "\n";
close $LOG;
