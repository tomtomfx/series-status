#!/usr/bin/perl

BEGIN {push @INC, '/var/www/cgi-bin/'}

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use Sys::Hostname;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(standard);
use DBI;
use betaSeries;

my $req = new CGI;
my $serieId = "";
my $showName = "";
my $config = "scriptsDir\/bin\/config";
my $fullConfig = "scriptsDir\/bin\/config";
my $logFile = "\/var\/www\/addSerie.log";
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";
my $verbose = 0;
my $time = localtime;

my $driver = "SQLite"; 
my $userid = "";
my $password = "";
my $serieDsn = "";
my $seriesDatabasePath = "";

# Read config file 
sub readConfigFile
{
	# Open config file
	open my $CONF, '<', $config or die "Cannot open $config - $!";
	my @conf = <$CONF>;
	close $CONF;
	foreach (@conf)
	{
	    chomp($_);
	    if ($_ =~ /^#/) {next;}			
	    if ($_ =~ /addSerieLogFile=(.*)$/){$logFile = $1;}
    	elsif ($_ =~ /betaSeriesKey=(.*)$/){$betaSeriesKey = $1;}
		elsif ($_ =~ /betaSeriesLogin=(.*)$/){$betaSeriesLogin = $1;}
		elsif ($_ =~ /betaSeriesPassword=(.*)$/){$betaSeriesPassword = $1;}
		elsif ($_ =~ /fullConfig=(.*)$/){$fullConfig = $1;}
		elsif ($_ =~ /databasePath=(.*)$/){$seriesDatabasePath = $1;}
	}
}

sub sendRequest
{
	my $ua = $_[0]; my $req = $_[1];
	my $resp = $ua->request($req);
	if ($resp->is_success) 
	{
		my $message = $resp->decoded_content;
		return $message;
	}
	else 
	{
		print "HTTP POST error code: ", $resp->code, "\n";
		print "HTTP POST error message: ", $resp->message, "\n";
		return 0;
	}
}

# Get hostname
my $host = hostname;
# Read config file
readConfigFile();
# open log file
open my $LOG, '>>', $logFile or die "Cannot open $logFile - $!";

# Program start
# retrieve serie name
if ($req->request_method() eq "POST") 
{
	if ($req->param('showId') eq "") 
	{
		print $LOG "[$time] $host AddSerie ERROR No serie to add specified\n";
		print $req->redirect('../series/series.php?status=failed&type=add');
	}
	else
	{
		$serieId = $req->param('showId');
		print $LOG "[$time] $host AddSerie INFO Serie to add: $serieId\n";
		
		# Connection to betaseries.com
		my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
		
		# Add serie to the followed shows on betaseries
		&betaSeries::addShow($verbose, $token, $betaSeriesKey, $serieId);
		$showName = &betaSeries::getShowNameFromId($verbose, $token, $betaSeriesKey, $serieId);
		print $LOG "[$time] $host AddSerie INFO Serie $showName found and added on betaSeries\n";

		# check if episodes exist in the database (show previously archived)
		# Connect to database
		$serieDsn = "DBI:$driver:dbname=$seriesDatabasePath";
		my $serieDbh = DBI->connect($serieDsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
		# Query to get all episodes from the show
		my $query = "SELECT * FROM unseenEpisodes WHERE Show=?";
		if ($verbose >= 2){print "$query\n";}
		my $sth = $serieDbh->prepare($query);
		$sth->execute("$showName");
		while(my $episode = $sth->fetchrow_hashref)
		{
			if ($verbose >= 1){print ("$episode->{'Id'}\n");}
			$serieDbh->do("UPDATE unseenEpisodes SET Archived=\'FALSE\' WHERE Id=\'$episode->{'Id'}\'");
		}
		$sth->finish();
		$serieDbh->disconnect();

		# Add the show to the config file
		# Ensure it is lower case
		$showName = lc($showName);
			
		# Read all config file
		open my $CONF, '<', $fullConfig or die "Cannot open $fullConfig - $!";
		my @conf = <$CONF>;
		close $CONF;
		# Check if show is already in config file
		my $alreadyThere = 0;
		foreach (@conf)
		{
			if ($_ eq "$showName,\n"){$alreadyThere = 1;}
		}
			
		if ($alreadyThere == 0)
		{
			# Re-write the config file adding the new show
			open my $CONF, '>', $fullConfig or die "Cannot open $fullConfig - $!";
			foreach my $line (@conf)
			{
				if ($line =~ /\/shows/){print $CONF "$showName,\n";}
				print $CONF "$line";
			}
			close $CONF;
			print $LOG "[$time] $host AddSerie INFO Show $showName found and added in config file\n";
			print $req->redirect('../series/series.php?status=success&type=add');
		}
		print $LOG "[$time] $host AddSerie WARNING Show $showName already present in config file\n";
		print $req->redirect('../series/series.php?status=success&type=add');
	}
}
close $LOG;
