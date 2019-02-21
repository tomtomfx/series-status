#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use DBI;
use Net::FTP;
use FindBin;
use lib "$FindBin::Bin/../lib";
use utils;
 
my @tvShows;
my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $verbose = 0;

my $outDirectory = "";

# Database variables
my $databasePath = "";
my $dsn = "";
my $driver = "SQLite"; 
my $userid = "";
my $password = "";

# Tablet ssh server
my $tabletHostname = "";
my $tabletPort = "2221";
my $ftpUser = "";
my $ftpPassword = "";

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
		if ($_ =~ /databasePath=(.*)$/){$databasePath = $1;}
		elsif ($_ =~ /outDirectory=(.*)$/){$outDirectory = $1;}
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
	print "Database path: $databasePath\n";
	print "Output directory: $outDirectory\n";
	print "\n";
}

# Start writing logs with date and time
my $time = localtime;
my $date = "";

# Connect to database
$dsn = "DBI:$driver:dbname=$databasePath";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Database opened successfully\n";}	

#########################################################################################
# Get list of tablets and set their ftp status
my $query = "SELECT * FROM Tablets";
if ($verbose >= 2){print "$query\n";}
my $sth = $dbh->prepare($query);
$sth->execute();
my $tablets = $sth->fetchall_hashref('id');
foreach my $tablet (values %{$tablets})
{
	my $tabletInfo = $tablet;
	if ($verbose >= 1) {print Dumper($tabletInfo);}
	# Try an FTP connection...
	my $status = "Down";
	my $ftp = Net::FTP->new($tabletInfo->{"ip"}, Port => $tabletPort);
	if ($ftp){if ($ftp->login($tabletInfo->{"ftpUser"}, $tabletInfo->{"ftpPassword"})){$status = "OK";}}
	# ...and update the status
	$dbh->do("UPDATE Tablets SET status=\'$status\' WHERE Id=\'$tabletInfo->{\"id\"}\'");
}
$sth->finish();


#########################################################################################
# Get episodes with copy requested
my @episodes;
my %episodeLocation;
$query = "SELECT * FROM unseenEpisodes WHERE CopyRequested=\"true\"";
if ($verbose >= 2){print "$query\n";}
$sth = $dbh->prepare($query);
$sth->execute();
while(my $episode = $sth->fetchrow_hashref)
{
	# print Dumper($episode->{"copyRequested"});
	if ($verbose >= 1) {print Dumper($episode);}
	push (@episodes, $episode);
}
$sth->finish();

# Copy all files that have copy requested
foreach my $episode (@episodes)
{
	my $tabletId = $episode->{"Tablet"};
	my $tabletInfo = $tablets->{$tabletId};
	# Connect to tablet through FTP
	my $ftp = Net::FTP->new($tabletInfo->{"ip"}, Port => $tabletPort, Timeout => 120, Debug => 0, Passive => 1);
	if ($ftp)
	{
		$ftp->login($tabletInfo->{"ftpUser"}, $tabletInfo->{"ftpPassword"});
		if ($verbose >= 1){print "Connected to '$tabletInfo->{\"id\"}' as '$tabletInfo->{\"ftpUser\"}'\n";}
		# Set binary and passive mode
		$ftp->binary();
		# print ("$episodeLocation{$episode->{\"Id\"}}\n");
		if (-f $episode->{"Location"})
			{$ftp->put($episode->{"Location"});}
		$ftp->binary();
		my $srtLocation = $episode->{"Location"};
		$srtLocation =~ s/\..{3}/\.srt/;
		# print "$srtLocation\n";
		if (-f $srtLocation)
			{$ftp->put($srtLocation);}
		$ftp->quit();
	}
}

#########################################################################################
# Check episodes present on tablet and update database and set their status to "Copied"
# Connect to tablet through FTP
my @fileList;
foreach my $tablet (values %{$tablets})
{
	my $tabletInfo = $tablet;
	# Try an FTP connection...

	my $ftp = Net::FTP->new($tabletInfo->{"ip"}, Port => $tabletPort, Degug => 0, Passive => 1);
	if ($ftp)
	{
		$ftp->login($tabletInfo->{"ftpUser"}, $tabletInfo->{"ftpPassword"});
		if ($verbose >= 1){print "Connected to '$tabletInfo->{\"id\"}' as '$tabletInfo->{\"ftpUser\"}'\n";}
		@fileList = $ftp->ls;
		if ($verbose >= 1){print Dumper(@fileList);}
	}
	foreach my $file (@fileList)
	{
		if ($file =~ /(.*)\..{3}$/)
		{
			my $id = $1;
			
			# Specific for Marvel
			$id =~ s/marvels/marvel/i;
			
			$id =~ s/(\w+)/\u\L$1/g;
			if ($id =~ /(.*) - s(\d*)e(\d*)/i) 
			{
				my $season = sprintf("%02d", $2);
				$id = "$1 - S".$season."E$3";
			}
			if ($verbose >= 1){print "$id\n";}
			my $query = "SELECT COUNT(*) FROM unseenEpisodes WHERE Id=?";
			if ($verbose >= 2){print "$query\n";}
			$sth = $dbh->prepare($query);
			$sth->execute($id);
			if ($sth->fetch()->[0]) 
			{
				$dbh->do("UPDATE unseenEpisodes SET IsOnTablet=\'true\' WHERE Id=\'$id\'");
				$dbh->do("UPDATE unseenEpisodes SET CopyRequested=\'false\' WHERE Id=\'$id\'");
				$dbh->do("UPDATE unseenEpisodes SET Tablet=\'$tabletInfo->{\"id\"}\' WHERE Id=\'$id\'");
			}
		}
		$sth->finish();
	}

	# Disconnect FTP and close DB
	if ($ftp){$ftp->quit();}
}
$dbh->disconnect();
