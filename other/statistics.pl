#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use DBI;
use Date::Manip;

my @tvShows;
my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $verbose = 0;
my $databasePath = "";
my $graphsPath = "";

# Database variables
my $driver = "SQLite"; 
my $dsn = "";
my $userid = "";
my $password = "";

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
		elsif ($_ =~ /databasePath=(.*)$/)
		{
			$databasePath = $1;
		}
		elsif ($_ =~ /graphsPath=(.*)$/)
		{
			$graphsPath = $1;
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
	# print "Table  \"$table_name\" exists: $exists\n";
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
	print "Database path: $databasePath\n";	
	print "Data path: $graphsPath\n";	
	print "\n";
}

#########################################################################################
# Open Database connection
$dsn = "DBI:$driver:dbname=$databasePath";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Database opened successfully\n";}	
my $exists = does_table_exist($dbh, "Episodes");
if ($exists == 0)
{
	if ($verbose >= 1){print ("No table \"Episodes\" available in this database\n");}
	exit;
}

#########################################################################################
# Create a csv file for the number of episodes seen and downloaded
# Get last date and values in the csv file
# Check if header need to be written

my $episodesCsv = "$graphsPath\/episodes.csv";
my @lastInfos = ("");
my $writeHeader = 1; 
if (-e $episodesCsv)
{
	open my $EP, '<', $episodesCsv or die "Cannot open download list file: $episodesCsv\n";
	my @eps = reverse <$EP>;
	close $EP;
	
	foreach my $line (@eps)
	{
		chomp ($line);
		if ($line eq ""){next;}
		@lastInfos = split(/,/, $line);
		last;
	}
}
if ($verbose >= 1) {print (Dumper(@lastInfos));}
if ($lastInfos[0] ne "") {$writeHeader = 0;}


#########################################################################################
# Number of episodes seen & number of episodes downloaded
my %episodes;
my $lastDate = $lastInfos[0];
# Get all downloaded and seen episodes per date
my $query = "SELECT DownloadDate, WatchDate FROM Episodes ORDER BY DownloadDate DESC";
my $sth = $dbh->prepare($query);
$sth->execute();
my $row;
while ($row = $sth->fetchrow_arrayref()) 
{
	my $downloadDate = @$row[0];
	my $watchDate = @$row[1];
	if ($downloadDate ne '')
	{
		if ($downloadDate =~ /(.*) .*/){$downloadDate = $1;}
		if ($lastDate eq "" || Date_Cmp($lastDate, $downloadDate) < 0)
		{
			if (exists($episodes{$downloadDate}{"downloaded"})){$episodes{$downloadDate}{"downloaded"} += 1;}
			else {$episodes{$downloadDate}{"downloaded"} = 1;}
			if ($verbose >= 1) {print "$downloadDate\t$episodes{$downloadDate}{\"downloaded\"}\n";}
		}
	}
	if ($watchDate ne '')
	{
		if ($watchDate =~ /(.*) .*/){$watchDate = $1;}
		if ($lastDate eq "" || Date_Cmp($lastDate, $watchDate) < 0)
		{
			if (exists($episodes{$watchDate}{"seen"})){$episodes{$watchDate}{"seen"} += 1;}
			else {$episodes{$watchDate}{"seen"} = 1;}
			if ($verbose >= 1) {print "$watchDate\t$episodes{$watchDate}{\"seen\"}\n";}
		}
	}
}

#########################################################################################
# Open output file and append new data
open my $EPS, '>>', $episodesCsv or die "Cannot open download list file: $episodesCsv\n";
#Write header if necessary
if ($writeHeader)
{
	print $EPS "Date,Episodes downloaded,Episodes seen\n";
}

# Write new downloaded and seen number of episodes
foreach my $key (sort keys(%episodes))
{
	if (!exists($episodes{$key}{"downloaded"})){$episodes{$key}{"downloaded"} = 0;}
	if (!exists($episodes{$key}{"seen"})){$episodes{$key}{"seen"} = 0;}
	print $EPS "$key,$episodes{$key}{\"downloaded\"},$episodes{$key}{\"seen\"}\n";
}
close $EPS;

#########################################################################################
# Get the mean number of days between download and watch per serie
# Graph on the three last months (download time)
my $episodesDelayCsv = "$graphsPath\/episodesDelay.csv";
my %episodeDelaySeries;

# Change date format and compare to the max watch date in the database
my $startDate =  DateCalc("today","- 3 month");
if ($verbose >= 1) {print "Start date: $startDate\n";}

# Get all downloaded and seen episodes per date
$query = "SELECT DownloadDate, WatchDate, SerieName FROM Episodes";
$sth = $dbh->prepare($query);
$sth->execute();
while ($row = $sth->fetchrow_arrayref()) 
{
	my $downloadDate = @$row[0];
	my $watchDate = @$row[1];
	my $serieName = @$row[2];
	if ($downloadDate ne '' && $watchDate ne '')
	{
		if (Date_Cmp($startDate, $watchDate) <= 0)
		{
			if ($downloadDate =~ /(.*) .*/){$downloadDate = $1;}
			if ($watchDate =~ /(.*) .*/){$watchDate = $1;}
			my $delta = DateCalc($downloadDate,$watchDate);
			if ($delta =~ /0:0:0:0:(\d+):0:0/) {$delta = $1/24;}
			if ($verbose >= 1) {print "$downloadDate - $watchDate - $delta\n";}
			
			if (exists($episodeDelaySeries{$serieName}{'delta'})) {$episodeDelaySeries{$serieName}{'delta'} += $delta;}
			else {$episodeDelaySeries{$serieName}{'delta'} = $delta;}
			if (exists($episodeDelaySeries{$serieName}{'divisor'})) {$episodeDelaySeries{$serieName}{'divisor'} += 1;}
			else {$episodeDelaySeries{$serieName}{'divisor'} = 1;}
		}
		else {next;}
	}
	else {next;}
}
if ($verbose >= 1) {print (Dumper(%episodeDelaySeries));}

#########################################################################################
# Open output file and write data
open $EPS, '>', $episodesDelayCsv or die "Cannot open download list file: $episodesDelayCsv\n";

# Write header
print $EPS "Serie,Mean delay\n";

# Write delta between download and watch per serie
foreach my $serie (sort keys(%episodeDelaySeries))
{
	if ($episodeDelaySeries{$serie}{'divisor'} != 0)
	{
		my $meanDelay = int(($episodeDelaySeries{$serie}{'delta'} / $episodeDelaySeries{$serie}{'divisor'}) + 0.5);
		if ($meanDelay != 0)
		{
			$serie =~ s/_/ /ig;
			print $EPS "$serie,$meanDelay\n";
		}
	}
}
close $EPS;


#########################################################################################
# Get the number of episode seen per serie in the last 1 month
my $episodeSeenMonthlyCsv = "$graphsPath\/episodesSeenMonthly.csv";
my %series;
# Change date format and compare to the max watch date in the database
$startDate =  DateCalc("today","- 31 days");
if ($verbose >= 1) {print "Start date: $startDate\n";}

# Get all downloaded and seen episodes per date
$query = "SELECT WatchDate, SerieName FROM Episodes";
$sth = $dbh->prepare($query);
$sth->execute();
while ($row = $sth->fetchrow_arrayref()) 
{
	my $watchDate = @$row[0];
	my $serieName = @$row[1];
	if ($watchDate ne '')
	{
		if (Date_Cmp($startDate, $watchDate) <= 0)
		{
			if(exists($series{$serieName})) {$series{$serieName} += 1;}
			else {$series{$serieName} = 1;}
		}
	}
	else {next;}
}

#########################################################################################
# Open output file and write data
open $EPS, '>', $episodeSeenMonthlyCsv or die "Cannot open download list file: $episodeSeenMonthlyCsv\n";

# Write header
print $EPS "Serie,Number of episodes\n";

# Write delta between download and watch per serie
foreach my $serie (sort keys(%series))
{
	my $numberEpisodes = $series{$serie};
	if ($numberEpisodes != 0)
	{
		$serie =~ s/_/ /ig;
		print $EPS "$serie,$numberEpisodes\n";
	}
}
close $EPS;

#########################################################################################
# Create the number of unseen episodes over time
my $episodeUnseenCsv = "$graphsPath\/episodesUnseen.csv";

# Open output file and write data
open $EPS, '>', $episodeUnseenCsv or die "Cannot open download list file: $episodeUnseenCsv\n";

# Write header
print $EPS "Date,Number of unseen episodes\n";

# Get all data from serieStatus
$query = "SELECT * FROM serieStatus";
$sth = $dbh->prepare($query);
$sth->execute();
while ($row = $sth->fetchrow_arrayref()) 
{
	my $date = @$row[0];
	my $nbUnseenEpisodes = @$row[1];
	print $EPS "$date,$nbUnseenEpisodes\n";
}

# Close file
close $EPS;

#########################################################################################
# Create a csv file for the number of episodes seen and downloaded per month over a year
my $episodesMonthlyCsv = "$graphsPath\/episodesMonthly.csv";

# Number of episodes seen & number of episodes downloaded
my %episodesMonthly;
my $firstMonth = UnixDate(DateCalc("today","- 1 year"), "%Y-%m");
if ($verbose >= 1) {print "First month: $firstMonth\n";}

# Get all downloaded and seen episodes per date
$query = "SELECT DownloadDate, WatchDate FROM Episodes ORDER BY DownloadDate DESC";
$sth = $dbh->prepare($query);
$sth->execute();
while ($row = $sth->fetchrow_arrayref()) 
{
	my $downloadDate = @$row[0];
	my $watchDate = @$row[1];
	if ($downloadDate ne '')
	{
		my $downloadMonth = "";
		if ($downloadDate =~ /(.*) .*/){$downloadMonth = UnixDate($1, "%Y-%m");}
		if ($firstMonth eq "" || Date_Cmp($firstMonth, $downloadMonth) < 0)
		{
			if (exists($episodesMonthly{$downloadMonth}{"downloaded"})){$episodesMonthly{$downloadMonth}{"downloaded"} += 1;}
			else {$episodesMonthly{$downloadMonth}{"downloaded"} = 1;}
			if ($verbose >= 1) {print "$downloadMonth\t$episodesMonthly{$downloadMonth}{\"downloaded\"}\n";}
		}
	}
	if ($watchDate ne '')
	{
		my $wtachMonth = "";
		if ($watchDate =~ /(.*) .*/){$wtachMonth = UnixDate($1, "%Y-%m");}
		if ($lastDate eq "" || Date_Cmp($firstMonth, $wtachMonth) < 0)
		{
			if (exists($episodesMonthly{$wtachMonth}{"seen"})){$episodesMonthly{$wtachMonth}{"seen"} += 1;}
			else {$episodesMonthly{$wtachMonth}{"seen"} = 1;}
			if ($verbose >= 1) {print "$wtachMonth\t$episodesMonthly{$wtachMonth}{\"seen\"}\n";}
		}
	}
}

#########################################################################################
# Open output file and append new data
open $EPS, '>', $episodesMonthlyCsv or die "Cannot open download list file: $episodesMonthlyCsv\n";
#Write header if necessary
print $EPS "Month,Episodes downloaded,Episodes seen\n";

# Write new downloaded and seen number of episodes
foreach my $key (sort keys(%episodesMonthly))
{
	if (!exists($episodesMonthly{$key}{"downloaded"})){$episodesMonthly{$key}{"downloaded"} = 0;}
	if (!exists($episodesMonthly{$key}{"seen"})){$episodesMonthly{$key}{"seen"} = 0;}
	print $EPS "$key,$episodesMonthly{$key}{\"downloaded\"},$episodesMonthly{$key}{\"seen\"}\n";
}
close $EPS;


#########################################################################################
# Disconnect from database
$dbh->disconnect();
if ($verbose >=1) {print "Database closed successfully\n";}	
