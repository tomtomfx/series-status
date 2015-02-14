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
	my ($serie, $episodes, $verbose) = @_;
	# Remove (year)
	if ($serie =~ /(.*) \(\d{4}\)/){$serie = $1;}
	# Specific for marvel's agent of shield
	$serie =~ s/\'s/s/i;
	my $torrentzLink = "http://torrentz.eu";
	my $kickass = "";
	my $newtorrents = "";
	my $t1337 = "";
	$serie =~ s/ /+/g;
	if ($verbose >= 1) {print "http://torrentz.eu/search?f=$serie+$episodes\n";}
	# Get torrent URL
	my @url = split("\n", get("http://torrentz.eu/search?f=$serie+$episodes+x264"));
	foreach (@url)
	{
		if ($_ =~ /<dl><dt><a href=\"(\/\w*)"><b>/)
		{
			$torrentzLink = $torrentzLink.$1;
			if ($verbose >= 1) {print "$torrentzLink\n";}
			last;
		}
	}
	@url = split("\n", get($torrentzLink));
	foreach (@url)
	{
		if($_ =~ /href=\"(https:\/\/kickass.so\/[\w|\-]*\.html)\"/ || $_ =~ /href=\"(https:\/\/kickass.to\/[\w|\-]*\.html)\"/){$kickass = $1;}
		if($_ =~ /href=\"(http:\/\/www.newtorrents.info\/torrent\/.*\/.*\.html\?nopop=1)\"/){$newtorrents = $1;}
		if($_ =~ /href=\"(http:\/\/1337x.to\/torrent\/\d*\/.*\/)\".*1337x.to<\/span>/){$t1337 = $1;}
	}
	if ($verbose >= 1) {print ("kickass = $kickass\nnewTorrents = $newtorrents\n1337 = $t1337\n");}
	
	if ($kickass ne "" && get($kickass) eq "") {$kickass = "";}
	if ($newtorrents ne "" && get($newtorrents) eq "") {$newtorrents = "";}
	if ($t1337 ne "" && get($t1337) eq "") {$t1337 = "";}
	
	if ($kickass ne "")
	{
		@url = split("\n", get($kickass));
		foreach (@url)
		{
			if ($_ =~ /title="Download verified torrent file" href="(http:\/\/.*)\" class=/) 
			{
				if ($verbose >= 1) {print "$1\n";}
				return $1;
			}
		}
	}
	elsif ($newtorrents ne "")
	{
		@url = split("\n", get($newtorrents));
		foreach (@url)
		{
			if ($_ =~ /Download<\/td><td><a href='\/(down\.php\?id=.*)'><b>download this torrent/) 
			{
				if ($verbose >= 1) {print "$1\n";}
				return "http:\/\/www.newtorrents.info\/".$1;
			}
		}
	}
	elsif ($t1337 ne "")
	{
		@url = split("\n", get($t1337));
		foreach (@url)
		{
			if ($_ =~ /href="(http:\/\/torcache.net\/torrent\/.*\.torrent)/) 
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
		push (@torrentUrl, getTorrentUrl($serie, $episode, $verbose));
		if ($torrentUrl[0] eq "") {$result = 1;}
		if ($verbose >= 1) {print "$torrentUrl[0]\n";}
		print $LOG "[$time] $host - Download - INFO - serie=$serie - $episode - url=$torrentUrl[0]\n";
		if ($torrentUrl[0] ne "")
		{
			my $xmlrpc = Frontier::Client->new('url' => 'http://192.168.1.3/RPC2');
			$result = $xmlrpc->call("load_start", @torrentUrl);
		}
		if ($result eq "0") {print $LOG "[$time] $host - Download - SUCCESS - serie=$serie - $episode --> OK\n";}
		else {print $LOG "[$time] $host - Download - ERROR - serie=$serie - $episode --> Failed\n"; next;}
		
		sleep(20);
	}
}

print $LOG "\n";
close $LOG;
