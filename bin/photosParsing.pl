#!/usr/bin/perl

use strict;
use warnings;
use Sys::Hostname;
use Date::Manip;
use Data::Dumper;
use DBI;

my @tvShows;
my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $verbose = 0;
my $photosDirectory = "";
my $photosDatabasePath = "";
my $photosDatabaseLogFile = "";
my $photosHTTPDirectory = "";

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
		elsif ($_ =~ /photosDirectory=(.*)$/)
		{
			$photosDirectory = $1;
		}
		elsif ($_ =~ /photosDatabasePath=(.*)$/)
		{
			$photosDatabasePath = $1;
		}
		elsif ($_ =~ /photosDatabaseLogFile=(.*)$/)
		{
			$photosDatabaseLogFile = $1;
		}
		elsif ($_ =~ /photosHTTPDirectory=(.*)$/)
		{
			$photosHTTPDirectory = $1;
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

#########################################################################################
# Beginning of program
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
	print "Photos directory: $photosDirectory\n";
	print "Photos database log file: $photosDatabaseLogFile\n";	
	print "Photos database path: $photosDatabasePath\n";	
	print "Photos HTTP path: $photosHTTPDirectory\n";
	print "\n";
}

# open log file
open my $LOG, '>>', $photosDatabasePath;

# Get hostname
my $host = hostname;

#########################################################################################
# Open or create database and create "photos" table
$dsn = "DBI:$driver:dbname=$photosDatabasePath";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
if ($verbose >=1) {print "Opened database successfully\n";}	
# Check if table "photos" exists
my $exists = does_table_exist($dbh, "photos");
if ($exists == 1)
{
	if ($verbose >= 1){print ("Table photos already exists\n");}
}
else
{
	if ($verbose >= 1){print ("photos table does not exists. Creating one.\n");}
	$dbh->do("DROP TABLE IF EXISTS photos");
	$dbh->do("CREATE TABLE photos(name TEXT PRIMARY KEY, album TEXT, date TEXT, path TEXT)");
	my $time = localtime;
	print $LOG "[$time] $host database INFO \"Table \"photos\" created in the database\"\n";
}
# Check if table "albums" exists
$exists = does_table_exist($dbh, "albums");
if ($exists == 1)
{
	if ($verbose >= 1){print ("Table albums already exists\n");}
}
else
{
	if ($verbose >= 1){print ("albums table does not exists. Creating one.\n");}
	$dbh->do("DROP TABLE IF EXISTS albums");
	$dbh->do("CREATE TABLE albums(name TEXT PRIMARY KEY, date TEXT, numberOfPhotos INT, cover TEXT)");
	my $time = localtime;
	print $LOG "[$time] $host database INFO \"Table \"albums\" created in the database\"\n";
}

#########################################################################################
# Open photos directory
opendir my $DIR, $photosDirectory or die "Cannot open photos directory: $photosDirectory\n";
my @directories = readdir $DIR;
close $DIR;

foreach (@directories)
{
	if (-d "$photosDirectory\\$_" && $_ ne '.' && $_ ne '..')
	{
		if ($verbose >= 1){print "$photosDirectory\\$_\n";}
		my $currentDir = $_;
		if ($_ =~ /(.*) - (.*)$/)
		{
			my $albumDate = $1;
			my $albumName = $2;
			my $defaultPhotoName = "";
			if ($verbose >= 1){print "Processing $albumName\n";}
			opendir my $ALB, "$photosDirectory\\$_" or die "Cannot open album directory: $_\n";
			my @album = readdir $ALB;
			close $ALB;
						
			foreach my $photo (@album)
			{
				if ($photo =~ /(.*\.jpg)/)
				{
					my $photoName = $1;
					$defaultPhotoName = $photoName;
					if ($verbose >= 1){print "$photoName\t$albumName\t$albumDate\n";}
					# Query to check if the episode already exists
					my $query = "SELECT COUNT(*) FROM photos WHERE name=?";
					my $sth = $dbh->prepare($query);
					$sth->execute($photoName);
					if (!$sth->fetch()->[0]) 
					{
						if ($verbose >= 1){print "photo $photoName is not referenced\n";}
						my $photoInfo = "\'$photoName\', \'$albumName\', \'$albumDate\', \'$photosHTTPDirectory\/$currentDir\/$photoName\'";
						$dbh->do("INSERT INTO photos VALUES($photoInfo)");
						my $time = localtime;
						print $LOG "[$time] $host database INFO \"$photoName added\"\n";
					}
				}
			}
			
			# Query the number of images in this album
			my $query = "SELECT COUNT(*) FROM photos WHERE album=?";
			my $sth = $dbh->prepare($query);
			$sth->execute($albumName);
			my $numberOfPhotos = $sth->fetch()->[0];
			if ($verbose >= 1){print "There are $numberOfPhotos photos in $albumName\n";}
			# Select the album thumbnail image
			my $thumbNumber = int(rand($numberOfPhotos)) + 1;
			if ($defaultPhotoName =~ /.*(\d+.jpg)/){$defaultPhotoName =~ s/$1/$thumbNumber\.jpg/;}
			# Check if album already exists
			$query = "SELECT COUNT(*) FROM albums WHERE name=?";
			$sth = $dbh->prepare($query);
			$sth->execute($albumName);
			if (!$sth->fetch()->[0]) 
			{
				if ($verbose >= 1){print "Album $albumName is not referenced\n";}
				my $albumInfo = "\'$albumName\', \'$albumDate\', \'$numberOfPhotos\', \'$photosHTTPDirectory\/$currentDir\/$defaultPhotoName\'";
				$dbh->do("INSERT INTO albums VALUES($albumInfo)");
				my $time = localtime;
				print $LOG "[$time] $host database INFO \"$albumName added\"\n";
			}
			else
			{
				$dbh->do("UPDATE albums SET numberOfPhotos=\'$numberOfPhotos\' WHERE name=\'$albumName\'");
			}
		}
	}
}
# Disconnect from database
$dbh->disconnect();
if ($verbose >=1) {print "Closed database successfully\n";}	
#########################################################################################

close $LOG;