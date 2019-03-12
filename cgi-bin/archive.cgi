#!/usr/bin/perl

BEGIN {push @INC, '/var/www/cgi-bin/'}

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use Sys::Hostname;
use DBI;
use CGI;
use betaSeries;

my $req = new CGI;
my $serie = "";
my $config = "scriptsDir\/bin\/config";
my $logFile = "";
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

# Program start
# Get hostname
my $host = hostname;

# Read config file
readConfigFile();

# open log file
open my $LOG, '>>', $logFile or die "Cannot open $logFile - $!";

# retrieve serie name
if ($req->request_method() eq "POST") 
{
	if ($req->param('showId') eq "") 
	{
		print $LOG "[$time] $host ArchiveShow ERROR No show to archive specified\n";
		print $req->redirect('../series/series.php?status=failed&type=add');
	}
	else
	{
		$serie = $req->param('showId');
		print $LOG "[$time] $host ArchiveShow INFO Serie to archive: $serie\n";
		
		# Connection to betaseries.com
		my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
		# Get serie ID from title
		my $serieId = &betaSeries::searchSerie($verbose, $token, $betaSeriesKey, $serie);
		if ($serieId != 0)
		{
			# Add serie to the followed shows on betaseries
			&betaSeries::archiveShow($verbose, $token, $betaSeriesKey, $serieId);
			print $LOG "[$time] $host ArchiveShow INFO Serie $serie found and archived on betaSeries\n";

			#########################################################################################
			# Mark all episodes in the series database as archived
			# Connect to database
			$serieDsn = "DBI:$driver:dbname=$seriesDatabasePath";
			my $serieDbh = DBI->connect($serieDsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
			# Query to get all episodes from a show
			my $query = "SELECT * FROM unseenEpisodes WHERE Show=?";
			if ($verbose >= 2){print "$query\n";}
			my $sth = $serieDbh->prepare($query);
			$sth->execute("$serie");
			while(my $episode = $sth->fetchrow_hashref)
			{
				if ($verbose >= 1){print ("$episode->{'Id'}\n");}
				$serieDbh->do("UPDATE unseenEpisodes SET Archived=\'TRUE\' WHERE Id=\'$episode->{'Id'}\'");
			}
			$sth->finish();
			$serieDbh->disconnect();

			print $LOG "[$time] $host ArchiveShow INFO All episodes from $serie have been set to archived\n";
			print $req->redirect('../series/series.php?status=success&type=archive');
		}
		else
		{
			print $LOG "[$time] $host ArchiveShow ERROR $serie cannot be found on betaSeries\n";
			print $req->redirect('../series/series.php?status=failed&type=archive');
		}
	}
}
close $LOG;
