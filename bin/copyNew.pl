#!/usr/bin/perl

use strict;
use warnings;

my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $inputDir = "";
my $outputDir = "";
my $logFile = "";
my $verbose = 0;

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
		    last;
		}
	    if ($_ =~ /copyLogFile=(.*\.log)/)
	    {
		    $logFile = $1;
    	}
		elsif ($_ =~ /outDirectory=(.*)$/)
		{
			$inputDir = $1;
		}
		elsif ($_ =~ /copyDirectory=(.*)$/)
		{
			$outputDir = $1;
		}
	}
}

sub getFileInfos
{
	my $file = $_[0];
	my $verbose = $_[1];
	my @infos;
	if ($file =~ /(.*) - s(\d+)e(\d+)\./)
	{
		$infos[0] = $1; $infos[1] = $2; $infos[2] = $3;
	}
	else{$infos[0] = "";}
	if ($verbose >= 3)
	{
		print "Serie: $infos[0], Saison: $2, Episode: $3\n";
	}
	return @infos;
}

foreach my $arg (@ARGV)
{
	if ($arg eq '-v') {$verbose = 1;}
	elsif ($arg eq '-vv'){$verbose = 2;}
	elsif ($arg eq '-vvv'){$verbose = 3;}
	else {$verbose = 0;}
}
# Read config file
readConfigFile($verbose);
if ($verbose >= 2)
{
	# Print available shows
	print "Input: $inputDir\n";
	print "Output: $outputDir\n";
	print "Log: $logFile\n";
	print "\n";
}
# open log file
open my $LOG, '>>', $logFile or die "Cannot open $logFile";

################################################
# Start writing logs with date and time
my $time = localtime;
print $LOG "##### $time #####\n";
################################################

################################################
# Move already watched episodes
if ($verbose >= 1) {print "##### Move viewed episodes #####\n";}
print $LOG "##### Move viewed episodes #####\n";
# open output directory
opendir(DL, $outputDir) or die "Cannot open $outputDir";;
my @outDir = readdir(DL);
close DL;

foreach my $file (@outDir)
{
	my $fileFound = 0;
	if (-d "$outputDir\/$file") {next;}
	if ($file !~ /\.mp4$/ && $file !~ /\.avi$/) {next;}
	# Check if file already viewed on the server
	my @infos = getFileInfos($file, $verbose);
	# open input serie directory
	my @inDir;
	if ($infos[0] eq ""){next;}
	$infos[0] =~ s/^(\w)/\U$1/;
	my $showDir = "$inputDir\/$infos[0] - Saison $infos[1]";
	if ($verbose >= 2) {print "Input directory: $showDir\n";}
	if (-d $showDir)
	{
		opendir(DL, $showDir) or die "Cannot open $showDir";
		@inDir = readdir(DL);
		close DL;
	}
	foreach (@inDir)
	{
		if ($_ eq $file) {$fileFound = 1; last;}
		else {next;}
	}
	if ($fileFound == 1)
	{
		$file =~ s/\.mp4//; $file =~ s/\.avi//;
		my $folder = "$outputDir\/$infos[0] - Saison $infos[1]";
		if (-d $folder)
		{
			print $LOG "move $file\n";
			my $moveMp4 = "mv \"$outputDir\/$file\.mp4\" \"$folder\/.\"";
			my $moveSrt = "mv \"$outputDir\/$file\.srt\" \"$folder\/.\"";
			if ($verbose >= 2) {print "$moveMp4\n$moveSrt\n";}
			system($moveMp4);
			system($moveSrt);
		}
		else
		{
			print $LOG "remove $file\n";
			my $removeMp4 = "rm \"$outputDir\/$file\.mp4\"";
			my $removeSrt = "rm \"$outputDir\/$file\.srt\"";
			if ($verbose >= 2) {print "$removeMp4\n$removeSrt\n";}
			system($removeMp4);
			system($removeSrt);
		}
	}
	else {if ($verbose >= 1) {print "$file has not been viewed\n";}} 
}
################################################

################################################
# Read output directory to get the shows to copy
# open output directory
opendir(DL, $outputDir) or die "Cannot open $outputDir";
@outDir = readdir(DL);
close DL;
print $LOG "##### Update directories #####\n";
if ($verbose >= 2) {print "##### Update directories #####\n";}
foreach (@outDir)
{
	if (-d "$outputDir\/$_") 
	{
		if ($_ eq ".." || $_ eq ".") {next;}
		# Open show directory to get the last synchronised episode
		my $latestEp = 0;
		opendir(DL, "$outputDir\/$_");
		my @showDir = readdir(DL);
		close DL;
		foreach my $show (@showDir)
		{
			if ($show =~ /.srt$/ || $show =~ /\.xml$/ || $show =~ /\.jpg$/ || $show =~ /\.metathumb$/ || $show =~ /^\./) {next;}
			my @infos = getFileInfos($show, $verbose);
			if ($infos[2] ne "" && $infos[2] >= $latestEp) {$latestEp = $infos[2];}
		}
		if ($verbose >= 1){print "$_ - Latest episode: $latestEp\n";}
		# Check for new episodes
		opendir(DL, "$inputDir\/$_") or die "Cannot open $inputDir\/$_";
		my @inDir = readdir(DL);
		close DL;
		foreach my $show (@inDir)
		{
			if ($show =~ /.srt$/ || $show =~ /\.xml$/ || $show =~ /\.jpg$/ || $show =~ /\.metathumb$/ || $show =~ /^\./) {next;}
			my @infos = getFileInfos ($show, $verbose);
			if ($infos[2] ne "" && $infos[2] > $latestEp)
			{
				$show =~ s/.mp4//;
				$show =~ s/.avi//;
				print $LOG "copy $show\n";
				my $copyMp4 = "cp \"$inputDir\/$_\/$show.mp4\" \"$outputDir\/$_\/.\"";
				my $copySrt = "cp \"$inputDir\/$_\/$show.srt\" \"$outputDir\/$_\/.\"";
				if ($verbose >= 2) {print "$copyMp4\n$copySrt\n";}
				system($copyMp4);
				system($copySrt);
			}
		}	
	}
	else {next;}
}
################################################

################################################
# Check non-watched episodes and copy if new
print $LOG "##### Update new episodes #####\n";
if ($verbose >= 2) {print "##### Update new episodes #####\n";}
# open input directory
opendir(DL, $inputDir) or die "Cannot open $inputDir";
my @inDir = readdir(DL);
close DL;
# open output directory
opendir(DL, $outputDir) or die "Cannot open $outputDir";
@outDir = readdir(DL);
close DL;

foreach my $file (@inDir)
{
	my $fileFound = 0;
	if (-d "$inputDir\/$file") {next;}
	if ($file =~ /\.srt$/ || $file =~ /\.xml$/ || $file =~ /\.metathumb$/ || $file =~ /\.jpg$/ || $file =~ /^\./) {next;}
	# Check if file already exists
	foreach (@outDir)
	{
		if ($_ eq $file) {$fileFound = 1; last;}
		else {next;}
	}
	if ($fileFound == 0)
	{
		$file =~ s/\.mp4//;
		$file =~ s/\.avi//;
		print $LOG "copy $file\n";
		my $copyMp4 = "cp \"$inputDir\/$file.mp4\" \"$outputDir\/.\"";
		my $copySrt = "cp \"$inputDir\/$file.srt\" \"$outputDir\/.\"";
		if ($verbose >= 2) {print "$copyMp4\n$copySrt\n";}
		system($copyMp4);
		system($copySrt);
	}
	else {if ($verbose >= 1) {print "$file exists already\n";}} 
}
################################################

print $LOG "\n";
close $LOG;
