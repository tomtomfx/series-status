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
	
	# Specific for Mr. Robot
	$serie =~ s/Mr\./Mr/i;
	
	my $torrentzLink = "http://torrentz.eu";
	my $kickass = "";
	my $torlock = "";
	my $t1337 = "";
	my $yourbittorrent = "";
	my $torrentbit = "";
	
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
		if($_ =~ /href=\"(https:\/\/kickass.so\/[\w|\-]*\.html)\"/ || $_ =~ /href=\"(https:\/\/kickass.to\/[\w|\-]*\.html)\"/ || $_ =~ /href=\"(https:\/\/kat.cr\/[\w|\-]*\.html)\"/){$kickass = $1;}
		if($_ =~ /href=\"(http:\/\/www\.torlock\.com\/torrent\/.*\/.*\.html)\" rel=\"e\"><span.*torlock.com<\/span>/){$torlock = $1;}
		if($_ =~ /href=\"(http:\/\/1337x.to\/torrent\/\d*\/.*\/)\".*1337x.to<\/span>/ || $_ =~ /href=\"(https:\/\/1337x.to\/torrent\/\d*\/.*\/)\" rel=\"e\">.*1337x\.to/){$t1337 = $1;}
		if($_ =~ /href=\"http:\/\/www.yourbittorrent.com\/torrent\/(\d+)\/.*\.html\" rel=\"e\"><span.*yourbittorrent.com<\/span>/){$yourbittorrent = $1;}
		if($_ =~ /href=\"http:\/\/www.torrentbit.net\/torrent\/(\d*)\/.*\/\" rel=\"e\"><span.*torrentbit.net<\/span>/){$torrentbit = $1;}
	}
	if ($verbose >= 1) {print ("kickass = $kickass\ntorlock = $torlock\n1337 = $t1337\nyourBittorrent = $yourbittorrent\ntorrentbit = $torrentbit\n");}

	if ($kickass ne "" && get($kickass) eq "") {$kickass = "";}
	if ($torlock ne "" && get($torlock) eq "") {$torlock = "";}
	if ($t1337 ne "" && get($t1337) eq "") {$t1337 = "";}
	# if ($yourbittorrent ne "" && get($yourbittorrent) eq "") {$yourbittorrent = "";}
	
	if ($yourbittorrent ne "")
	{
		return "http:\/\/yourbittorrent.com\/down\/$yourbittorrent.torrent";
	}
	elsif ($torrentbit ne "")
	{
		return "http:\/\/www.torrentbit.net\/get\/$torrentbit";
	}
	elsif ($torlock ne "")
	{
		@url = split("\n", get($torlock));
		foreach (@url)
		{
			if ($_ =~ /href=\"\/(tor\/.*\.torrent)\"><img src=http:\/\/cdn.torlock.com\/dlbutton2\.png/) 
			{
				if ($verbose >= 1) {print "$1\n";}
				return "http:\/\/www.torlock.com\/".$1;
			}
		}
	}
	elsif ($kickass ne "")
	{
		@url = split("\n", get($kickass));
		foreach (@url)
		{
			if ($_ =~ /title="Download verified torrent file" href="(http:\/\/.*)\"><i class=/) 
			{
				if ($verbose >= 1) {print "$1\n";}
				return $1;
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
