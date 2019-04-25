#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use LWP::Simple;
use DBI;
use FindBin;
use lib "$FindBin::Bin/../lib";
use utils;
use betaSeries;
 
my @tvShows;
my $config = "scriptsDir\/bin\/config";
my $verbose = 0;
my $sendMail = 0;

# Database variables
my $seriesDatabasePath = "";
my $dsnSerie = "";
my $tabletDatabasePath = "";
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
		if ($_ =~ /databasePath=(.*)$/){$seriesDatabasePath = $1;}
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

if ($#ARGV < 0) {die "Usage: seriesStatus sendMail [verbose]\n";}

foreach my $arg (@ARGV)
{
	if ($arg eq '-v') {$verbose = 1;}
	elsif ($arg eq '-vv'){$verbose = 2;}
	else {$verbose = 0;}
}
if ($ARGV[0] == 1){$sendMail = 1;}

# Read config file
readConfigFile($verbose);

if ($verbose >= 1)
{
	# Print configuration infos
	print "Send email: $sendMail\n";
	print "\n";
}

# Start writing logs with date and time
my $time = localtime;
my $date = "";
if ($time =~ /(.*) \d*:\d*:\d*/) {$date = $1;}
if ($verbose >=1) {print "Looking for logs of $date\n";}

# Create the transport. Using gmail for this example
my $transport = Email::Sender::Transport::SMTP::TLS->new(
	host     => 'smtp.gmail.com',
	port     => 587,
	username => 'films.vouille@gmail.com',
	password => '9Rc0kFFb'
);
 
my %shows = ();

# Get files to be read from series database
$dsnSerie = "DBI:$driver:dbname=$seriesDatabasePath";
my $dbhSerie = DBI->connect($dsnSerie, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
my @episodes;
my $query = "SELECT * FROM unseenEpisodes";
if ($verbose >= 2){print "$query\n";}
my $sth = $dbhSerie->prepare($query);
$sth->execute();
while(my $episode = $sth->fetchrow_hashref)
{
	push (@episodes, $episode);
}
$sth->finish();
$dbhSerie->disconnect();

# Process files in the database
foreach (@episodes)
{
	$shows{$_->{'Show'}}{$_->{'Id'}}{'IdBetaseries'} = $_->{'IdBetaseries'};
	$shows{$_->{'Show'}}{$_->{'Id'}}{'Title'} = $_->{'Title'};
	$shows{$_->{'Show'}}{$_->{'Id'}}{'Location'} = $_->{'Location'};
	
	# Managed status
	if ($_->{'Status'} eq "To be watched"){$shows{$_->{'Show'}}{$_->{'Id'}}{'Status'} = "<success>To be watched<success>";}
	elsif ($_->{'Status'} eq "No subtitles found"){$shows{$_->{'Show'}}{$_->{'Id'}}{'Status'} = "<warning>No subtitles found<warning>";}
	elsif ($_->{'Status'} eq "Download launched"){$shows{$_->{'Show'}}{$_->{'Id'}}{'Status'} = "<info>Download launched<info>";}
	elsif ($_->{'Status'} eq "Download failed"){$shows{$_->{'Show'}}{$_->{'Id'}}{'Status'} = "<danger>Download failed<danger>";}
}
	
if ($verbose >= 1) {print Dumper (%shows);}
my @keys = sort keys %shows;

my $episodes = 0;
foreach (@keys)
{
	my @eps = keys %{$shows{$_}};
	$episodes += $#eps + 1;
}

foreach my $serie (@keys)
{
	my @episodes = sort keys %{$shows{$serie}};
	my $nbEpisodes = $#episodes + 1;
	if ($verbose >= 1) {print "$serie \($nbEpisodes\)\n"; print Dumper @episodes;}
	foreach my $ep (@episodes)
	{
		my $title = $shows{$serie}{$ep}{'Title'};
		my $epId = $shows{$serie}{$ep}{'IdBetaseries'};
		my $label = "";		
		my $epStatus = "";
		my $epRef = "";
		if ($shows{$serie}{$ep}{'Status'} =~ /<(.*)>(.*)<.*>/)
		{
			$label = $1;
			$epStatus = $2;
		}
		if ($ep =~ /.* - (.*)/){$epRef = $1;}				
	}
}

# Manage email
if ($sendMail && @keys)
{
	# Create email content
	my $mailContent = "Bonjour Thomas,\nVoici le résumé \"séries\" du jour:\n\n";
	foreach my $serie (sort keys %shows)
	{
		my @episodes = sort keys %{$shows{$serie}};
		my $nbEpisodes = $#episodes + 1;
		$mailContent = $mailContent."$serie \($nbEpisodes\)\n";
		foreach my $episode (@episodes)
		{
			$shows{$serie}{$episode}{'Status'} =~ s/<danger>//g; $shows{$serie}{$episode}{'Status'} =~ s/<success>//g;
			$shows{$serie}{$episode}{'Status'} =~ s/<warning>//g; $shows{$serie}{$episode}{'Status'} =~ s/<info>//g;
			$mailContent = $mailContent."\t$episode --> $shows{$serie}{$episode}{'Status'}\n";
		}
	}
	$mailContent = $mailContent."\nBonne soirée.\n";
	if ($verbose >= 1) {print $mailContent;}

	# Send email
	my $email = Email::Simple->create(
	header => [
	  From    => 'films.vouille@gmail.com',
	  To      => 'thomas.fayoux@gmail.com',
	  Subject => "Series status $date",
	],
	body => $mailContent,
	);
	 
	# send the mail
	sendmail( $email, {transport => $transport} );
	if ($verbose >= 1) {print "Mail sent to thomas.fayoux\@gmail.com !\n";}
}
