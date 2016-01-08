#!/usr/bin/perl

use strict;
use warnings;
use Sys::Hostname;
use Data::Dumper;
use DBI;
use Date::Manip;
use FindBin;
use lib "$FindBin::Bin/../lib";
use utils;

my @tvShows;
my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $verbose = 0;
my $downloadLogFile = "";
my $seenLogFile = "";
my $databasePath = "";
my $databaseLogFile = "";
my $outputHtmlPage = "";

# Database variables
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
		elsif ($_ =~ /downloadLogFile=(.*)$/)
		{
			$downloadLogFile = $1;
		}
		elsif ($_ =~ /seenLogFile=(.*)$/)
		{
			$seenLogFile = $1;
		}
		elsif ($_ =~ /databaseLogFile=(.*)$/)
		{
			$databaseLogFile = $1;
		}
		elsif ($_ =~ /databasePath=(.*)$/)
		{
			$databasePath = $1;
		}
		elsif ($_ =~ /outputHtmlPage=(.*)$/)
		{
			$outputHtmlPage = $1;
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
	# print "Table \"$table_name\" exists: $exists\n";
	return $exists;
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
	# Print infos
	print "Unseen log file: $seenLogFile\n";
	print "Download log file: $downloadLogFile\n";	
	print "Statistics log file: $databaseLogFile\n";	
	print "Database path: $databasePath\n";	
	print "\n";
}

# open log file
open my $LOG, '>>', $databaseLogFile;

# Get hostname
my $host = hostname;

#########################################################################################
# Get new downloaded episodes
open my $DOWN, '<', $downloadLogFile or die "Cannot open download list file: $downloadLogFile\n";
my @downloads = <$DOWN>;
close $DOWN;
my $log = "";
my %episodes = ();
my $episodeID = "";
my $maxDownloadDate = "";

# Retrieve latest downloadDate from database
$dsn = "DBI:$driver:dbname=$databasePath";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Opened database successfully\n";}	
my $exists = does_table_exist($dbh, "Episodes");
if ($exists == 1)
{
	my $query = "SELECT DownloadDate FROM Episodes ORDER BY DownloadDate DESC LIMIT 1";
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my @row = $sth->fetchrow();
	$maxDownloadDate = $row[0];
	if ($verbose >= 1){print ("Latest download date is: $maxDownloadDate\n");}
}
else
{
	$maxDownloadDate = "";
}
$dbh->disconnect();
if ($verbose >=1) {print "Closed database successfully\n";}	
#########################################################################################

foreach (@downloads)
{
	if ($_ ne "\n")	
	{
		$log = $_;
		chomp($log);
		if ($verbose >= 2) {print "$log\n";}
		if ($log =~ /\[(.*)\] .* GetSubtitles INFO \"(.*) - s(\d+)e(\d+)\" Subtitles found/)
		{
			my $date = $1;
			my $serie = $2;
			my $seasonNumber = $3;
			my $epNumber = $4;

			# Change date format and compare to the max watch date in the database
			$date = UnixDate($date, "%Y-%m-%d %H:%M:%S.000");
			if (($maxDownloadDate ne "") && (Date_Cmp($date, $maxDownloadDate) <= 0)){next;}
			
			$serie =~ s/ /_/g;
			$episodeID = $serie." - s".$seasonNumber."e".$epNumber;
			if ($verbose >= 2) {print "$episodeID\n";}
			if (!exists($episodes{$episodeID}))
			{
				$episodes{$episodeID}{"serie"} = $serie;
				$episodes{$episodeID}{"season"} = $seasonNumber;
				$episodes{$episodeID}{"episodeNumber"} = $epNumber;
			}
			$episodes{$episodeID}{"downloadDate"} = $date;
			$episodes{$episodeID}{"downloadDateFound"} = 1;
			if (exists($episodes{$episodeID}{"downloadRetries"})) {$episodes{$episodeID}{"downloadRetries"} += 1;}
			else {$episodes{$episodeID}{"downloadRetries"} = 1;}
		}
		elsif ($log =~ /\[(.*)\] .* GetSubtitles ERROR \"(.*)\" No subtitle found/)
		{
			my $date = $1;
			my $file = $2;
			
			# Change date format and compare to the max watch date in the database
			$date = UnixDate($date, "%Y-%m-%d %H:%M:%S.000");
			if (($maxDownloadDate ne "") && (Date_Cmp($date, $maxDownloadDate) <= 0)){next;}
			
			my @infos = &utils::GetInfos($file, @tvShows);
			$infos[0] =~ s/ /_/g;
			$infos[1] = $infos[1] + 0;
			$episodeID = "$infos[0] - s$infos[1]e$infos[2]";
			if ($verbose >= 2) {print "$episodeID - download Retry +1\n";}
			if (exists($episodes{$episodeID}{"downloadRetries"})) {$episodes{$episodeID}{"downloadRetries"} += 1;}
			else 
			{
				$episodes{$episodeID}{"serie"} = $infos[0];
				$episodes{$episodeID}{"season"} = $infos[1];
				$episodes{$episodeID}{"episodeNumber"} = $infos[2];
				$episodes{$episodeID}{"downloadRetries"} = 1;
				
			}
			$episodes{$episodeID}{"downloadDate"} = "";
			$episodes{$episodeID}{"downloadDateFound"} = 0;
		}
	}
}
#########################################################################################

#########################################################################################
# Get seen episodes
# Get date of the latest episode seen in DB
my $maxWatchDate = "";
$dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Opened database successfully\n";}	
$exists = does_table_exist($dbh, "Episodes");
if ($exists == 1)
{
	my $query = "SELECT WatchDate FROM Episodes ORDER BY WatchDate DESC LIMIT 1";
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my @row = $sth->fetchrow();
	$maxWatchDate = $row[0];
	if ($verbose >= 1){print ("Latest watch date is: $maxWatchDate\n");}
}
else
{
	$maxWatchDate = "";
}
$dbh->disconnect();
if ($verbose >=1) {print "Closed database successfully\n";}	

# Get episode info
# Open downloads file list
open my $SEEN, '<', $seenLogFile or die "Cannot open download list file: $seenLogFile\n";
my @seen = <$SEEN>;
close $SEEN;

foreach (@seen)
{
	if ($_ ne "\n")	
	{
		$log = $_;
		chomp($log);
		if ($verbose >= 2) {print "$log\n";}
		if ($log =~ /\[(.*)\] .* EpisodeSeen INFO \"(.*) - s(\d+)e(\d+)\" watched/)
		{
			my $date = $1;
			my $serie = $2;
			my $seasonNumber = $3;
			my $epNumber = $4;
			
			# Change date format and compare to the max watch date in the database
			$date = UnixDate($date, "%Y-%m-%d %H:%M:%S.000");
			if (($maxWatchDate ne "") && (Date_Cmp($date, $maxWatchDate) <= 0)){next;}
			
			$episodeID = $serie." - s".$seasonNumber."e".$epNumber;
			if ($verbose >= 2) {print "$episodeID\n";}
			if (!exists($episodes{$episodeID}))
			{
				$episodes{$episodeID}{"serie"} = $serie;
				$episodes{$episodeID}{"season"} = $seasonNumber;
				$episodes{$episodeID}{"episodeNumber"} = $epNumber;
			} 
			$episodes{$episodeID}{"watchDate"} = $date;
			$episodes{$episodeID}{"watchDateFound"} = 1;
		}
	}
}
#########################################################################################

#########################################################################################
# Complete episodes if missing data
foreach my $ep (keys(%episodes))
{
	if (!exists($episodes{$ep}{"downloadDate"}))
	{
		$episodes{$ep}{"downloadDate"} = "";
		$episodes{$ep}{"downloadDateFound"} = 0;
	}
	if (!exists($episodes{$ep}{"downloadRetries"})){$episodes{$ep}{"downloadRetries"} = 0;}
	if (!exists($episodes{$ep}{"watchDate"}))
	{
		$episodes{$ep}{"watchDate"} = "";	
		$episodes{$ep}{"watchDateFound"} = 0;
	}
}
#########################################################################################

# print all new episodes found in the logs
if ($verbose >= 2) {print Dumper %episodes;}

#########################################################################################
# Add episodes in the database
# Connect to database	
$dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Opened database successfully\n";}	

$exists = does_table_exist($dbh, "Episodes");
if ($exists == 1)
{
	if ($verbose >= 1){print ("Table Episodes already exists\n");}
}
else
{
	if ($verbose >= 1){print ("Episodes table does not exists. Creating one.\n");}
	$dbh->do("DROP TABLE IF EXISTS Episodes");
	$dbh->do("CREATE TABLE Episodes(Id TEXT PRIMARY KEY, SerieName TEXT, SeasonNumber INT, EpisodeNumber INT, DownloadDate TEXT, WatchDate TEXT, DownloadRetries INT)");
	my $time = localtime;
	print $LOG "[$time] $host database INFO \"Table \"Episodes\" created in the database\"\n";
}

foreach my $ep (keys(%episodes))
{
	my $status = "";
	# Query to check if the episode already exists
	my $query = "SELECT COUNT(*) FROM Episodes WHERE Id=?";
	if ($verbose >= 2){print "$query\n";}
	my $sth = $dbh->prepare($query);
	$sth->execute($ep);
	if ($sth->fetch()->[0]) 
	{
		# Already exists, need to update
		if ($verbose >= 1){print "$ep already exists\n";}
		if ($episodes{$ep}{"watchDateFound"})
		{
			$dbh->do("UPDATE Episodes SET WatchDate=\'$episodes{$ep}{\"watchDate\"}\' WHERE Id=\'$ep\'");
			if ($verbose >= 1){print "Watch date updated for $ep\n";}
			$status = "seen";
		}
		if ($episodes{$ep}{"downloadDateFound"})
		{
			$dbh->do("UPDATE Episodes SET DownloadDate=\'$episodes{$ep}{\"downloadDate\"}\' WHERE Id=\'$ep\'");
			$dbh->do("UPDATE Episodes SET DownloadRetries=\'$episodes{$ep}{\"downloadRetries\"}\' WHERE Id=\'$ep\'");
			if ($verbose >= 1){print "Download date and retries updated for $ep\n";}
			$status = "downloaded";
		}
		my $time = localtime;
		print $LOG "[$time] $host database INFO \"$ep updated \($status\)\"\n";
	}
	else
	{
		# Add episode
		my $episodeInfos = "\'$ep\', \'$episodes{$ep}{\"serie\"}\', $episodes{$ep}{\"season\"}, $episodes{$ep}{\"episodeNumber\"}, \'$episodes{$ep}{\"downloadDate\"}\', \'$episodes{$ep}{\"watchDate\"}\', $episodes{$ep}{\"downloadRetries\"}";
		if ($verbose >= 1){print "$episodeInfos\n";}
		$dbh->do("INSERT INTO Episodes VALUES($episodeInfos)");
		my $time = localtime;
		print $LOG "[$time] $host database INFO \"$ep added\"\n";
	}
}

#########################################################################################
# Get series status and add it in the database
# Open series status
open my $STATUS, '<', $outputHtmlPage or die "Cannot open download list file: $outputHtmlPage\n";
my @serieStatus = <$STATUS>;
close $STATUS;

my $nbUnseenEpisodes = 0;

foreach (@serieStatus)
{
	if ($_ =~ /<small> | (\d+) unseen episode(s)<\/small>/)	
	{
		$nbUnseenEpisodes = $1;
		if ($verbose >= 1){print "Unseen Episodes: $nbUnseenEpisodes\n";}
		last;
	}
	else {next;}
}
my $time = localtime;
my $date = UnixDate($time, "%Y-%m-%d");

# Create table SerieStatus if doesn't exist
$exists = does_table_exist($dbh, "SerieStatus");
if ($exists == 1)
{
	if ($verbose >= 1){print ("Table SerieStatus already exists\n");}
}
else
{
	if ($verbose >= 1){print ("SerieStatus table does not exist. Creating one.\n");}
	$dbh->do("DROP TABLE IF EXISTS SerieStatus");
	$dbh->do("CREATE TABLE SerieStatus(Date TEXT PRIMARY KEY, UnseenEpisodesNumber INT)");
	my $time = localtime;
	print $LOG "[$time] $host database INFO \"Table \"SerieStatus\" created in the database\"\n";
}

# Add new entry in the datbase
my $status = "";
# Query to check if the date already exists
my $query = "SELECT COUNT(*) FROM SerieStatus WHERE Date=?";
if ($verbose >= 2){print "$query\n";}
my $sth = $dbh->prepare($query);
$sth->execute($date);
if (!$sth->fetch()->[0]) 
{
	my $seriesInfos = "\'$date\', \'$nbUnseenEpisodes\'";
	if ($verbose >= 1){print "$seriesInfos\n";}
	$dbh->do("INSERT INTO SerieStatus VALUES($seriesInfos)");
	my $time = localtime;
	print $LOG "[$time] $host database INFO \"$seriesInfos added\"\n";
}
$sth->finish();

# Disconnect from database
$dbh->disconnect();
#########################################################################################

close $LOG;