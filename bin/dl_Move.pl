#!/usr/bin/perl

use strict;
use warnings;
use XML::Simple;
use LWP::Simple;
use Sys::Hostname;
use DBI;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use utils;
use betaSeries;

my @tvShows;
my $config = "scriptsDir\/bin\/config";
my $downloadDir = "";
my $outputDir = "";
my $serieDatabasePath = "";
my $logFile = "";
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";
my $tvdbKey = "";
my $verbose = 0;
my $time = localtime;
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
	    if ($_ =~ /shows$/){$readingShows = 1;next;}
		if ($_ =~ /\/shows$/){$readingShows = 0;next;}
		if ($readingShows == 1)
		{
			if ($_ =~ /(.*),/) 
			{
				push(@tvShows, $1);
				next;
			}
		}
	    if ($_ =~ /downloadLogFile=(.*\.log)/){$logFile = $1;}
    	elsif ($_ =~ /inDirectory=(.*)$/){$downloadDir = $1;}
		elsif ($_ =~ /outDirectory=(.*)$/){$outputDir = $1;}
		elsif ($_ =~ /databasePath=(.*)$/){$serieDatabasePath = $1;}
		elsif ($_ =~ /betaSeriesKey=(.*)$/){$betaSeriesKey = $1;}
		elsif ($_ =~ /betaSeriesLogin=(.*)$/){$betaSeriesLogin = $1;}
		elsif ($_ =~ /betaSeriesPassword=(.*)$/){$betaSeriesPassword = $1;}
		elsif ($_ =~ /tvdbApiKey=(.*)$/){$tvdbKey = $1;}
		elsif ($_ =~ /bannersPath=(.*)$/){$bannersPath = $1;}
		elsif ($_ =~ /backgroundsPath=(.*)$/){$backgroundsPath = $1;}
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
	# Print available shows
	print "logFile: $logFile\nbetaSeriesLogin: $betaSeriesLogin\nbetaSeriesKey: $betaSeriesKey\nbetaSeriesPassword: $betaSeriesPassword\ndownloadDir: $downloadDir\noutputDir: $outputDir\n";
	print "TVDB API key: $tvdbKey\n";
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

# Get the episodes to download from betaSeries
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my @episodeToSee = &betaSeries::getEpisodesToSee($verbose, $token, $betaSeriesKey);
#if ($verbose >= 1) {print Dumper(@episodeToSee);}

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
		my $doNotRemove = 0;
		opendir(DL, $serieDir);
		my @dlSerieDir = readdir(DL);
		close DL;
		foreach (@dlSerieDir)
		{			
			if ($_ =~ /\.avi/ or $_ =~ /\.mp4/ or $_ =~ /\.mkv/)
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
	if ($file !~ /\.avi/ and $file !~ /\.mp4/ and $file !~ /\.mkv/){next;}
	print "$file";
	if ($verbose >= 2) {print "\n";} 
	
	my $dbId = "";
	my $extension;
	if ($file =~ /\.avi/){$extension = "avi"}
	elsif($file =~ /\.mp4/){$extension = "mp4"}
	else{$extension = "mkv"}
	
	my $foundSub = 0; 
	my $sub;
	my @infos = &utils::GetInfos($file, @tvShows);
	if ($infos[0] ne "void")
	{
		$infos[1] = $infos[1] + 0;
		print $LOG "[$time] $host GetSubtitles INFO \"$infos[0] - s$infos[1]e$infos[2]\" Looking for subtitles\n";
	
		# Set file as downloaded on betaseries
		my $epId = "";
		my $show = "";
		my $title = "";
		my $saison = "";
		my $ep = "";
		my $status = "No subtitles found";
		foreach (@episodeToSee)
		{
			if ($_ =~ /(.*) - S(\d*)E(\d*) - (.*) - (\d*)/){$show = $1; $saison = $2; $ep = $3; $title = $4; $epId = $5}
			my $serie = $show;
			$title =~ s/'//g;
			$show =~ s/'//g;
			
			if ($show ne "")
			{
				# Get show banner if doesn't exists
				my $banner = "$bannersPath\/$show.jpg";
				unless (-e $banner)
				{
					if ($verbose >=1) {print "Banner $banner does not exist\n";}
					my $betaBanner = &betaSeries::getBannerPath($verbose, $token, $betaSeriesKey, $epId);
					if ($verbose >=1) {print "$betaBanner\n";}
					getstore($betaBanner, $banner);
				}
				# Get show background if doesn't exists
				my $background = "$backgroundsPath\/$show.jpg";
				unless (-e $background)
				{
					if ($verbose >=1) {print "Background $background does not exist\n";}
					my $betaBackground = &betaSeries::getShowBackground($verbose, $token, $betaSeriesKey, $epId);
					if ($verbose >=1) {print "$betaBackground\n";}
					getstore($betaBackground, $background);
				}
				
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
				# Specific for the blacklist: redemption
				$serie =~ s/blacklist: redemption/blacklist redemption/i;
				
				# if ($verbose >= 1) {print "$serie - $saison - $ep - $epId\n$infos[0] - $infos[1] - $infos[2]\n";}
				if ($infos[0] =~ /$serie/i && $infos[1] == $saison && $infos[2] == $ep)
				{
					if ($verbose >= 1) {print "$serie - $saison - $ep - $epId\n$infos[0] - $infos[1] - $infos[2]\n";}
					if ($verbose >= 1) {print "Episode found\n"}; 
					last;
				}
				else {$epId = "";}
			}
		}
		if ($epId ne "")
		{
			# Set episode downloaded on betaseries
			&betaSeries::setDownloaded($verbose, $token, $betaSeriesKey, $epId);
			$dbId = $show." - S".$saison."E".$ep;
		
			# Download subtitles
			if ($verbose >= 1){print ("Download subtitles\n");}
			betaSeries::getSubtitles($verbose, $token, $betaSeriesKey, $epId, $file, $downloadDir);
			
		}
		# open files directory
		opendir(DL, $downloadDir);
		my @subDlDir = readdir(DL);
		close DL;
		my $outFilename = "";
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
			# Get serie directory and create it if it does not exists
			my $serieDir = $infos[0];
			$serieDir =~ s/^(\w)/\U$1/;
			if (!-d "$outputDir\/$serieDir\/"){mkdir "$outputDir\/$serieDir\/";}
			$outFilename = "$outputDir\/$serieDir\/$infos[0] - s$infos[1]e$infos[2]";
			print $LOG "[$time] $host GetSubtitles INFO \"$infos[0] - s$infos[1]e$infos[2]\" Subtitles found \n";
			system("mv \"$downloadDir\/$file\" \"$outFilename.$extension\"");
			system("mv \"$downloadDir\/$sub\" \"$outFilename.srt\"");
			$status = "To be watched";
			print " --> OK\n";
		}
		else 
		{ 
			$time = localtime;
			print $LOG "[$time] $host GetSubtitles ERROR \"$file\" No subtitle found\n"; 
			print " --> Failed\n";
		}
		if ($epId ne "")
		{
			# Add or update unseen episode to the serie database
			# Query to check if the episode already exists
			if ($verbose >= 1){print "$dbId\n";}		
			my $query = "SELECT COUNT(*) FROM unseenEpisodes WHERE Id=?";
			if ($verbose >= 2){print "$query\n";}
			my $sth = $dbh->prepare($query);
			$sth->execute($dbId);
			if ($sth->fetch()->[0]) 
			{
				if ($verbose >= 1){print "$dbId already exists\n";}
				$dbh->do("UPDATE unseenEpisodes SET Status=\'$status\' WHERE Id=\'$dbId\'");
				if ($outFilename ne ""){$dbh->do("UPDATE unseenEpisodes SET Location=\'$outFilename.$extension\', IsOnTablet=\'false\', CopyRequested=\'false\' WHERE Id=\'$dbId\'");}
			}
			else
			{
				# Add episode
				my $episodeInfos = "";
				if ($outFilename ne ""){$episodeInfos = "\'$dbId\', \'$show\', \'$title\', \'$epId\', \'$status\', \'$outFilename.$extension\', \'\', \'\', \'false\', \'false\'";}
				else {$episodeInfos = "\'$dbId\', \'$show\', \'$title\', \'$epId\', \'$status\', \'\', \'\', \'\', \'\', \'\'";}
				if ($verbose >= 1){print "$episodeInfos\n";}
				$dbh->do("INSERT INTO unseenEpisodes VALUES($episodeInfos)");
			}
			$sth->finish();
		}
	}
	else
	{
		print $LOG "[$time] $host GetSubtitles ERROR \"$file\" No show, season or episode found\n";
	}
	#print $LOG "\n";
}
$dbh->disconnect();
close $LOG;
