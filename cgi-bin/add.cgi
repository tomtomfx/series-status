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
use betaSeries;

my $req = new CGI;
my $serie = "";
my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $fullConfig = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $logFile = "\/var\/www\/addSerie.log";
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";
my $verbose = 0;
my $time = localtime;

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
	    if ($_ =~ /addSerieLogFile=(.*)$/)
	    {
		    $logFile = $1;
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
		elsif ($_ =~ /fullConfig=(.*)$/)
		{
			$fullConfig = $1;
		}
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
	if ($req->param('serieName') eq "") 
	{
		print $LOG "[$time] $host AddSerie ERROR No serie to add specified\n";
		print $req->redirect('../series/series.php?status=failed&type=add');
	}
	else
	{
		$serie = $req->param('serieName');
		print $LOG "[$time] $host AddSerie INFO Serie to add: $serie\n";
		
		# Connection to betaseries.com
		my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
		# Get serie ID from title
		my $serieId = &betaSeries::searchSerie($verbose, $token, $betaSeriesKey, $serie);
		if ($serieId != 0)
		{
			# Add serie to the followed shows on betaseries
			&betaSeries::addShow($verbose, $token, $betaSeriesKey, $serieId);
			print $LOG "[$time] $host AddSerie INFO Serie $serie found and added on betaSeries\n";

			# Add the serie to the config file
			# Ensure it is lower case
			$serie = lc($serie);
			
			# Read all config file
			open my $CONF, '<', $fullConfig or die "Cannot open $fullConfig - $!";
			my @conf = <$CONF>;
			close $CONF;
			# Check if serie is already in config file
			my $alreadyThere = 0;
			foreach (@conf)
			{
				if ($_ eq "$serie,\n"){$alreadyThere = 1;}
			}
			
			if ($alreadyThere == 0)
			{
				# Re-write the config file adding the new serie
				open my $CONF, '>', $fullConfig or die "Cannot open $fullConfig - $!";
				foreach my $line (@conf)
				{
					if ($line =~ /\/shows/){print $CONF "$serie,\n";}
					print $CONF "$line";
				}
				close $CONF;
				print $LOG "[$time] $host AddSerie INFO Serie $serie found and added in config file\n";
				print $req->redirect('../series/series.php?status=success&type=add');
			}
			print $LOG "[$time] $host AddSerie WARNING Serie $serie already present in config file\n";
			print $req->redirect('../series/series.php?status=success&type=add');
		}
		else
		{
			print $LOG "[$time] $host AddSerie ERROR Serie $serie cannot be found on betaSeries\n";
			print $req->redirect('../series/series.php?status=failed&type=add');
		}
	}
}
close $LOG;
