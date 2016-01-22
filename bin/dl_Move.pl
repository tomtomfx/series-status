#!/usr/bin/perl

use strict;
use warnings;
use XML::Simple;
use Sys::Hostname;
use FindBin;
use lib "$FindBin::Bin/../lib";
use utils;
use addic7ed;
use betaSeries;
use Data::Dumper;

my @tvShows;
my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $downloadDir = "";
my $outputDir = "";
my $logFile = "";
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";
my $verbose = 0;
my $time = localtime;

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
	    if ($_ =~ /shows/) 
    	{
			$readingShows = 1;
		    next;
		}
		if ($_ =~ /\/shows/) 
		{
			$readingShows = 0;
		    next;
		}

		if ($readingShows == 1)
		{
			if ($_ =~ /(.*),/) 
			{
				push(@tvShows, $1);
				next;
			}
		}
	    if ($_ =~ /downloadLogFile=(.*\.log)/)
	    {
		    $logFile = $1; 
    	}
    	elsif ($_ =~ /inDirectory=(.*)$/)
		{
			$downloadDir = $1;
		}
		elsif ($_ =~ /outDirectory=(.*)$/)
		{
			$outputDir = $1;
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
	# Print available shows
	print "Available shows : \n";
	# foreach my $printShow (@tvShows) { print "$printShow\n"; }
	print "logFile: $logFile\nbetaSeriesLogin: $betaSeriesLogin\nbetaSeriesKey: $betaSeriesKey\nbetaSeriesPassword: $betaSeriesPassword\ndownloadDir: $downloadDir\noutputDir: outputDir";
	print "\n";
}

# open log file
open my $LOG, '>>', $logFile;

# Get hostname
my $host = hostname;

# Get the episodes to download from betaSeries
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my @episodeToDownload = &betaSeries::getEpisodeToDownload($verbose, $token, $betaSeriesKey);
if ($verbose >= 1) {print Dumper(@episodeToDownload);}

# Check if series folders are presents
opendir(DL, $downloadDir);
my @dlDir = readdir(DL);
close DL;
foreach my $file (@dlDir)
{
	$time = localtime;
	my $serieDir = "$downloadDir\/$file";
	if (-d $serieDir && $file ne '.' && $file ne '..' && $file ne 'Config' && $file ne 'Films' && $file ne 'Series' && $file ne 'Temp' && $file ne 'Torrents')
	{
		#print "\"$serieDir\"\n";
		my $doNotRemove = 0;
		opendir(DL, $serieDir);
		my @dlSerieDir = readdir(DL);
		close DL;
		foreach (@dlSerieDir)
		{			
			if ($_ =~ /\.avi/ or $_ =~ /\.mp4/)
			{
				my $command = "mv \"$serieDir\/$_\" \"$downloadDir\"";
				system($command);
				$doNotRemove = 0;
			}
			if ($_ =~ /\.mp3/){$doNotRemove = 1;}
		}
		if ($doNotRemove == 0)
		{
			my $command = "rm -Rf \"$serieDir\"";
			system($command);
		}
	}
}

# open files directory
opendir(DL, $downloadDir);
@dlDir = readdir(DL);
close DL;

foreach my $file (@dlDir)
{
	$time = localtime;
	if ($file !~ /\.avi/ and $file !~ /\.mp4/)
	{
		next;
	}
	print "$file";
	if ($verbose >= 2) {print "\n";} 
	
	my $extension;
	if ($file =~ /\.avi/){$extension = "avi"}
	else{$extension = "mp4"}
	
	my $foundSub = 0; 
	my $sub;
	my @infos = &utils::GetInfos($file, @tvShows);
	if ($infos[0] ne "void")
	{
		$infos[1] = $infos[1] + 0;
		print $LOG "[$time] $host GetSubtitles INFO \"$infos[0] - s$infos[1]e$infos[2]\" Looking for subtitles\n";
	
		# Set file as downloaded on betaseries
		my $epId = "";
		foreach (@episodeToDownload)
		{
			my $serie, my $saison, my $ep;
			if ($_ =~ /(.*) - S(\d*)E(\d*) - (\d*)/){$serie = $1; $saison = $2; $ep = $3; $epId = $4}
			
			# Remove year if any
			$serie =~ s/ \(\d{4}\)//;
			# Specific for Marvel's agents of S.H.I.E.L.D.
			$serie =~ s/marvel\'s/marvel/i;
			# Specific for DC's legends of tomorrow
			$serie =~ s/dcs/dc/i;
			$serie =~ s/dc\'s/dc/i;
			# Remove (US)
			$serie =~ s/ \(US\)//;
			# Specific for Mr. Robot
			$serie =~ s/mr\./mr/i;
			
			if ($verbose >= 1) {print "$serie - $saison - $ep - $epId\n$infos[0] - $infos[1] - $infos[2]\n";}
			if ($infos[0] =~ /$serie/i && $infos[1] == $saison && $infos[2] == $ep)
			{
				if ($verbose >= 1) {print "Episode found\n"}; 
				last;
			}
			else {$epId = "";}
		}
		if ($epId ne ""){&betaSeries::setDownloaded($verbose, $token, $betaSeriesKey, $epId);}

		# Download subtitles
		close $LOG;
		&addic7ed::downloadSubtitles($file, $downloadDir, $logFile, $verbose);
		open $LOG, '>>', $logFile;
		
		# open files directory
		opendir(DL, $downloadDir);
		my @subDlDir = readdir(DL);
		close DL;
		foreach my $subFile (@subDlDir)
		{
			if ($subFile !~ /\.srt/)
			{
				next;
			}
			$foundSub = &utils::testSubFile($subFile, @infos);
			if ($foundSub == 1) 
			{
				$sub = $subFile;
				last;
			}
		}
		if ($foundSub == 1)
		{
			$time = localtime;
			my $outFilename = "$outputDir\/$infos[0] - s$infos[1]e$infos[2]";
			print $LOG "[$time] $host GetSubtitles INFO \"$infos[0] - s$infos[1]e$infos[2]\" Subtitles found \n";
			system("mv \"$downloadDir\/$file\" \"$outFilename.$extension\"");
			system("mv \"$downloadDir\/$sub\" \"$outFilename.srt\"");
			print " --> OK\n";
		}
		else 
		{ 
			$time = localtime;
			print $LOG "[$time] $host GetSubtitles ERROR \"$file\" No subtitle found\n"; 
			print " --> Failed\n";
		}
	}
	else
	{
		print $LOG "[$time] $host GetSubtitles ERROR \"$file\" No show, season or episode found\n";
	}
	
	#print $LOG "\n";
}
close $LOG;
