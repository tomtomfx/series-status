#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use LWP::Simple;

use FindBin;
use lib "$FindBin::Bin/../lib";
use tvdb;

my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $outputDir = "";
my $apiKey = "";
my $verbose = 0;

# Read config file 
sub readConfigFile
{
	my $verbose = $_[0];
	# Open config file
	if ($verbose >= 1) {print "Read config file\n"};
	open my $CONF, '<', $config or die "Cannot open $config";
	my @conf = <$CONF>;
	close $CONF;
	foreach (@conf)
	{
	    chomp($_);
	    if ($_ =~ /^#/) {next;}			

	    if ($_ =~ /outDirectory=(.*)/)
	    {
		    $outputDir = $1;
    	}
		if ($_ =~ /tvdbApiKey=(.*)/)
	    {
		    $apiKey = $1;
    	}
	}
}

# Create XML ouptut file
sub xmlInfoFile
{
	my ($verbose, $show, $outputFile, %episode) = @_;
	if ($verbose >= 1) {print "Episode: $show\n";}
	
	# open output file
	open my $FILE, '>', $outputFile or die "Cannot open output file: $outputFile\n";
	
	# Write content info in xml file
	print $FILE "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<details>\n";
	print $FILE "\t<title>$show - $episode{epTitle}<\/title>\n";
	print $FILE "\t<rating>$episode{epRating}<\/rating>\n";
	print $FILE "\t<studio>$episode{network}<\/studio>\n";
	print $FILE "\t<overview>$episode{epOverview}<\/overview>\n";
	# print Dumper $episode{'Actors'};
	print $FILE "\t<actor>";
	my @actors = sort keys(%{$episode{'Actors'}});
	my $nbActors = $#actors + 1;
	foreach (keys(%{$episode{'Actors'}}))
	{
		print $FILE "$_";
		$nbActors--;
		if ($nbActors > 0) {print $FILE ", ";}
	}
	print $FILE "<\/actor>\n";
	print $FILE "\t<thumbnail>$episode{Poster}<\/thumbnail>\n";
	print $FILE "\t<backdrop>$episode{epBackdrop}<\/backdrop>\n";
	print $FILE "<\/details>\n";
	
	close $FILE;
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
	print "Output directory: $outputDir\n";
	print "TheTVDB API key: $apiKey\n";
	print "\n";
}

opendir(DL, $outputDir);
my @dlDir = readdir(DL);
close DL;
foreach (@dlDir)
{
	if ($_ =~ /(.*)\.mp4/ || $_ =~ /(.*)\.avi/)
	{
		my $show = $1;
		my $outputFile = $outputDir."\/".$show.".xml";
		unless (-e $outputFile) 
		{
			my %episode = &tvdb::getTVDBInfo($verbose, $show, $apiKey, "fr");
			if ($verbose >= 1) {print Dumper %episode;}
			$show = ucfirst($show);
			xmlInfoFile($verbose, $show, $outputFile, %episode);
			# Download jpg file
			$show = lc($show);
			$outputFile = $outputDir."\/".$show.".metathumb";
			getstore($episode{'Poster'}, $outputFile);
		}
	}
}
