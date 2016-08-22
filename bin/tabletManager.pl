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
my $tabletDatabasePath = "";
my $driver = "SQLite"; 
my $dsn = "";
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
		if ($_ =~ /tabletDatabasePath=(.*)$/)
		{
			$tabletDatabasePath = $1;
		}
		elsif ($_ =~ /outDirectory=(.*)$/)
		{
			$outDirectory = $1;
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
	print "Tablet database path: $tabletDatabasePath\n";
	print "Output directory: $outDirectory\n";
	print "\n";
}

# Start writing logs with date and time
my $time = localtime;
my $date = "";

# Connect to database
$dsn = "DBI:$driver:dbname=$tabletDatabasePath";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Database opened successfully\n";}	

#########################################################################################
# Get list of tablets and set their ftp status
my $query = "SELECT * FROM Tablets";
if ($verbose >= 2){print "$query\n";}
my $sth = $dbh->prepare($query);
$sth->execute();
my $tablets = $sth->fetchall_hashref('id');
foreach my $tablet (keys($tablets))
{
	my $tabletInfo = $tablets->{$tablet};
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
$query = "SELECT * FROM Episodes WHERE copyRequested=\"true\"";
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

#########################################################################################
# Copy episodes with copy requested to tablet

# Get all video files available in the out directory
# Create a hash with ID and extension
my %episodeExtension;
# Open out directory
opendir (OUT, $outDirectory);
my @outDir = readdir(OUT);
close OUT;
foreach my $file (@outDir)
{
	if (($file =~ /(.*)\.(mp4)/) || ($file =~ /(.*)\.(mkv)/) || ($file =~ /(.*)\.(avi)/))
	{
		$episodeExtension{$1} = $2;
	}
	else {next;}
}

# Copy all files that have copy requested
foreach my $episode (@episodes)
{
	my $tabletId = $episode->{"tablet"};
	my $tabletInfo = $tablets->{$tabletId};
	# Connect to tablet through FTP
	my $ftp = Net::FTP->new($tabletInfo->{"ip"}, Port => $tabletPort, Timeout => 120, Debug => 1);
	if ($ftp)
	{
		$ftp->login($tabletInfo->{"ftpUser"}, $tabletInfo->{"ftpPassword"});
		if ($verbose >= 1){print "Connected to '$tabletInfo->{\"id\"}' as '$tabletInfo->{\"ftpUser\"}'\n";}
		# Set binary and passive mode
		$ftp->binary();
		$ftp->passive(0);
		if (0 and -f "$outDirectory\\$episode->{\"Id\"}.srt")
			{$ftp->put("$outDirectory\\$episode->{\"Id\"}.srt");}
		$ftp->binary();
		$ftp->passive(0);
		if (-f "$outDirectory\\$episode->{\"Id\"}.$episodeExtension{$episode->{\"Id\"}}")
			{$ftp->put("$outDirectory\\$episode->{\"Id\"}.$episodeExtension{$episode->{\"Id\"}}");}
		
		$ftp->quit();
	}
}

#########################################################################################
# Check episodes present on tablet and update database and set their status to "Copied"
# Connect to tablet through FTP
my @fileList;
foreach my $tablet (keys($tablets))
{
	my $tabletInfo = $tablets->{$tablet};
	# Try an FTP connection...

	my $ftp = Net::FTP->new($tabletInfo->{"ip"}, Port => $tabletPort);
	if ($ftp)
	{
		$ftp->login($tabletInfo->{"ftpUser"}, $tabletInfo->{"ftpPassword"});
		if ($verbose >= 1){print "Connected to '$tabletInfo->{\"id\"}' as '$tabletInfo->{\"ftpUser\"}'\n";}
		$ftp->passive(0);
		@fileList = $ftp->ls;
		if ($verbose >= 1){print Dumper(@fileList);}
	}
	foreach my $file (@fileList)
	{
		if ($file =~ /(.*)\..*/)
		{
			my $id = $1;
			my $query = "SELECT COUNT(*) FROM Episodes WHERE Id=?";
			if ($verbose >= 2){print "$query\n";}
			$sth = $dbh->prepare($query);
			$sth->execute($id);
			if ($sth->fetch()->[0]) 
			{
				$dbh->do("UPDATE Episodes SET isOnTablet=\'true\' WHERE Id=\'$id\'");
				$dbh->do("UPDATE Episodes SET copyRequested=\'false\' WHERE Id=\'$id\'");
				$dbh->do("UPDATE Episodes SET tablet=\'$tabletInfo->{\"id\"}\' WHERE Id=\'$id\'");
			}
		}
		$sth->finish();
	}

	# Disconnect FTP and close DB
	if ($ftp){$ftp->quit();}
}
$dbh->disconnect();