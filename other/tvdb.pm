
package tvdb;	

use strict;
use Data::Dumper;
use LWP::Simple;
use TVDB::API;

require Exporter;
my @ISA = qw/Exporter/;
my @EXPORT = qw/getTVDBInfo getBannerPath/;

sub getTVDBInfo
{
	# Get input info
	my ($verbose, $episode, $apiKey, $language) = @_;
	if ($verbose >= 1) {print "API key: $apiKey\nLanguage: $language\n";} 
	
	# Episode management
	my $serie = "";
	my $season = "";
	my $ep = "";
	if ($episode =~ /(.*) - s(\d*)e(\d*)/)
	{
		$serie = $1; $season = $2; $ep = $3 + 0;
		$serie = ucfirst($serie);
		if ($verbose >= 1) {print "Looking for $serie, season $season, episode $ep\n";}
	}
	else 
	{
		if ($verbose >= 1) {print "No serie, season or episode found in $episode\n";}
		return 0;
	}

	# Hash for output
	my %episodeHash;

	# Manage specific serie names
	if ($serie eq "The flash" || $serie eq "Rush" || $serie eq "Forever") {$serie = "$serie (2014)";}
	if ($serie eq "Castle") {$serie = "$serie (2009)";}
	$serie =~ s/S\.H\.I\.E\.L\.D\./SHIELD/;
	$serie =~ s/Marvel/marvel's/;
		
	# Get serie ID from theTVDB.com
	if ($verbose >=1) {print "Get serie ID from theTVDB.com\n";}
	my $page = get("http://thetvdb.com/api/GetSeries.php?seriesname=$serie&language=$language");
	if ($verbose >=2) {print Dumper $page;}
	my @serieInfo = split ('\n', $page);
	my $serieId;
	foreach (@serieInfo)
	{
		if ($_ =~ /<seriesid>(\d+)<\/seriesid>/) {$episodeHash{'serieId'} = $1;}
		if ($_ =~ /<Network>(.+)<\/Network>/) {$episodeHash{'network'} = $1;last;}
		if ($_ =~ /<banner>(.+)<\/banner>/) {$episodeHash{'banner'} = "http://thetvdb.com/banners/$1";}

		else {next;}
	}
	$episodeHash{'Poster'} = "http://thetvdb.com/banners/seasons/$episodeHash{'serieId'}-$season.jpg";

	# Get Actors from theTVDB.com
	if ($verbose >=1) {print "Get actors from theTVDB.com\n";}
	$page = get("http://thetvdb.com/api/$apiKey/series/$episodeHash{'serieId'}/actors.xml");
	if ($verbose >=2) {print Dumper $page;}
	my @actorsInfo = split ('\n', $page);
	my $actor;
	foreach (@actorsInfo)
	{
		if ($_ =~ /<Name>(.+)<\/Name>/) {$actor = $1;}
		if ($_ =~ /<Role>(.+)<\/Role>/) {$episodeHash{'Actors'}{$actor} = $1;}
	}

	# Get episode info from theTVDB.com
	if ($verbose >=1) {print "Get episode info from theTVDB.com\n";}
	$page = get("http://thetvdb.com/api/$apiKey/series/$episodeHash{'serieId'}/default/$season/$ep/$language.xml");
	if ($verbose >=2) {print Dumper $page;}
	my @episodeInfo = split ('\n', $page);
	my $epId, my $epTitle, my $epOverview, my $epRating;
	foreach (@episodeInfo)
	{
		if ($_ =~ /<id>(\d+)<\/id>/) {$episodeHash{'epId'} = $1;}
		if ($_ =~ /<EpisodeName>(.+)<\/EpisodeName>/) {$episodeHash{'epTitle'} = $1;}
		if ($_ =~ /<Overview>(.+)<\/Overview>/) {$episodeHash{'epOverview'} = $1;}
		if ($_ =~ /<Rating>(.+)<\/Rating>/) {$episodeHash{'epRating'} = $1;}
		if ($_ =~ /<FirstAired>(.+)<\/FirstAired>/) {$episodeHash{'epAired'} = $1;}
		if ($_ =~ /<filename>(.+)<\/filename>/) {$episodeHash{'epBackdrop'} = "http://thetvdb.com/banners/$1";}
		else {next;}
	}
	#print Dumper %episodeHash;
	return %episodeHash;
}

sub getBannerPath
{
	# Get input info
	my ($verbose, $serie, $language, $type, $apiKey) = @_;
	
	my $bannerPath = "";
	
	# Manage specific serie names
	if ($serie eq "the flash" || $serie eq "rush" || $serie eq "forever") {$serie = "$serie (2014)";}
	if ($serie eq "castle") {$serie = "$serie (2009)";}
	$serie =~ s/S\.H\.I\.E\.L\.D\./SHIELD/;
	$serie =~ s/Marvels/Marvel/i;
	$serie =~ s/Marvel/Marvel's/i;
	$serie =~ s/dc/dc's/;
	
	# Get serie ID from theTVDB.com
	if ($verbose >=1) {print "Get serie ID from theTVDB.com\n";}
	my $page = get("http://thetvdb.com/api/GetSeries.php?seriesname=$serie&language=$language");
	if ($verbose >=2) {print Dumper $page;}
	my @serieInfo = split ('\n', $page);
	
	if ($type eq "banner")
	{
		foreach (@serieInfo)
		{
			if ($_ =~ /<banner>(.+)<\/banner>/) {$bannerPath = "http://thetvdb.com/banners/$1"; last;}
			else {next;}
		}
	}
	elsif ($type eq "background")
	{
		my $tvdb = TVDB::API::new($apiKey, "en");
		$tvdb->setBannerPath("");
		my $fanart = $tvdb->getSeriesFanart($serie);
		$bannerPath = "http://thetvdb.com/banners/$fanart"
	}
	return $bannerPath;
}

1;