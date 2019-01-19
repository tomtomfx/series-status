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
use tvdb;
 
my @tvShows;
my $config = "\/home\/tom\/SubtitleManagement\/bin\/config";
my $verbose = 0;
my $htmlPage = "";
my $outputHtmlPage = "";
my $sendMail = 0;
my $bannersPath = "";

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
		if ($_ =~ /shows/){$readingShows = 1;next;}
		if ($_ =~ /\/shows/){$readingShows = 0;next;}
		if ($readingShows == 1)
		{
			if ($_ =~ /(.*),/) 
			{
				push(@tvShows, $1);
				next;
			}
		}
		if ($_ =~ /htmlPage=(.*)$/){$htmlPage = $1;}
		elsif ($_ =~ /outputHtmlPage=(.*)$/){$outputHtmlPage = $1;}
		elsif ($_ =~ /bannersPath=(.*)$/){$bannersPath = $1;}
		elsif ($_ =~ /tabletDatabasePath=(.*)$/){$tabletDatabasePath = $1;}
		elsif ($_ =~ /databasePath=(.*)$/){$seriesDatabasePath = $1;}
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

sub getTitle
{
	my ($verbose, $serie, $ep, @episodeToSee) = @_;
	foreach (@episodeToSee)
	{
		my $show = "";
		my $epNumber = "";
		my $title = "";
		my $epId = "";
		if ($verbose >= 1) {print "$_\n";}
		if (($_ =~ /(.*) \(\d{4}\) - s(\d*)e(\d*) - (.*) - (\d*)/i) || ($_ =~ /(.*) \(US\) - s(\d*)e(\d*) - (.*) - (\d*)/i) || ($_ =~ /(.*) - s(\d*)e(\d*) - (.*) - (\d*)/i)) 
		{			
			$show = lc($1);
			my $season = $2+0;
			my $episodeNumber = $3;
			$title = $4;
			$epId = $5;
			# Specific for Marvel's agents of S.H.I.E.L.D.
			$show =~ s/marvel\'s/marvel/i;	
			# Specific for MacGyver (2016)
			$show =~ s/macgyver/macgyver \(2016\)/i;	
			# Specific for S.W.A.T. (2017)
			$show =~ s/s\.w\.a\.t\./s\.w\.a\.t\. \(2017\)/i;	
			# Specific for Deception (2018)
			$show =~ s/deception/deception \(2018\)/i;	
			# Specific for DC's legends of tomorrow
			$show =~ s/dc's/dc/i;	
			# Specific for Mr Robot
			$show =~ s/mr\./mr/i;	
			# Specific for the blacklist: redemption
			$show =~ s/blacklist: redemption/blacklist redemption/i;			
		
			$epNumber = "s".$season."e".$episodeNumber; 
			if ($verbose >= 1) {print "$show - $serie\n$ep - $epNumber\n";}
		}
		if ($serie eq $show && $ep eq $epNumber)
		{
			if ($verbose >= 1) {print "$serie - $show\n$ep - $epNumber\n$title\n";}
			my $output = "$title - $epId";
			return $output;
		}
	}
	return "";
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
	print "Banners path: $bannersPath\n";
	print "Tablet database path: $tabletDatabasePath\n";
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
	password => 'ctl1032!'
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

# Update html page
# Read default page
open my $HTML, '<', $htmlPage or die "Cannot open input html file: $htmlPage\n";
my @htmlSource = <$HTML>;
close $HTML;
my @html;
foreach (@htmlSource)
{
	if ($_ =~ /<number of episodes>/){$_ =~ s/<number of episodes>/$episodes/;}
	if ($_ =~ /<insert text here>/)
	{
		$_ = "";
		foreach my $serie (@keys)
		{
			# create a new column for the serie
			$_ = $_."\t\t\t\t<div class=\"col-xs-12 col-sm-6 col-md-4\" id=\"series\">\n";
			$_ = $_."\t\t\t\t\t<div class=\"col-xs-12\" id=\"serie\">\n";
			
			my $banner = "$bannersPath\/$serie.jpg";
			unless (-e $banner)
			{
				if ($verbose >=2) {print "$banner does not exist\n";}
				my $tvdbBanner = tvdb::getBannerPath($verbose, $serie, "fr");
				if ($verbose >=2) {print "$tvdbBanner\n";}
				getstore($tvdbBanner, $banner);
			}
			my @episodes = sort keys %{$shows{$serie}};
			my $nbEpisodes = $#episodes + 1;
			# Add line for the banner
			$_ = $_."\t\t\t\t\t\t<div class=\"row\">\n";
			$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-12\"><h3 id=\"serieTitle\"><img id=\"banniere\" class=\"img-responsive\" src=\"../images/".$serie.".jpg\" alt=\"".$serie." \(".$nbEpisodes."\)\"></h3></div>\n";
			$_ = $_."\t\t\t\t\t\t</div>\n";
			if ($verbose >= 1) {print "$serie \($nbEpisodes\)\n"; print Dumper @episodes;}
			foreach my $ep (@episodes)
			{
				my $title = $shows{$serie}{$ep}{'Title'};
				my $epId = $shows{$serie}{$ep}{'IdBetaseries'};
				my $serieUnderscore = $serie;
				$serieUnderscore =~ s/ /_/g;
				$serieUnderscore =~ s/\(/\\\(/g;
				$serieUnderscore =~ s/\)/\\\)/g;
				
				my $epStatus = "";
				my $label = "";
				my $epRef = "";
				if ($shows{$serie}{$ep}{'Status'} =~ /<(.*)>(.*)<.*>/)
				{
					$label = $1;
					$epStatus = $2;
				}
				if ($ep =~ /.* - (.*)/){$epRef = $1;}
				
				# Print each episode
				$_ = $_."\t\t\t\t\t\t<div class=\"row\" id=\"episode\">\n";
				if ($epStatus eq "To be watched")
				{
					$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-1\"><a href=\"..\/cgi-bin\/update.cgi?ep=".$serieUnderscore."-".$epRef."-".$epId."\" class=\"glyphicon glyphicon-eye-open\" id=\"eye\"></a></div>\n";
				}
				else
				{
					$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-1\"><span class=\"glyphicon glyphicon-eye-open\" id=\"eye\"></span></div>\n";
				}
				$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-2\">".$epRef.":</div>\n";
				$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-5\">".$title."</div>\n";
				$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-4\"><span class=\"label label-".$label."\">".$epStatus."</span></div>\n";
				$_ = $_."\t\t\t\t\t\t</div>\n";
				
				#########################################################################################
				# Add episode available to be watched in the database
				if ($epStatus eq "To be watched")
				{
					# Connect to database
					$dsn = "DBI:$driver:dbname=$tabletDatabasePath";
					my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
					if ($verbose >=1) {print "Database opened successfully\n";}	
					# Check table exists
					my $exists = does_table_exist($dbh, "Episodes");
					if ($exists == 1){if ($verbose >= 1){print ("Table Episodes already exists\n");}}
					else
					{
						if ($verbose >= 1){print ("Episodes table does not exists. Creating one.\n");}
						$dbh->do("DROP TABLE IF EXISTS Episodes");
						$dbh->do("CREATE TABLE Episodes(Id TEXT PRIMARY KEY, SerieName TEXT, EpisodeNumber TEXT, EpisodeTitle TEXT, tablet TEXT, copyRequested BOOL, isOnTablet BOOL)");
					}
					# Query to check if the episode already exists
					my $query = "SELECT COUNT(*) FROM Episodes WHERE Id=?";
					if ($verbose >= 2){print "$query\n";}
					my $sth = $dbh->prepare($query);
					$sth->execute("$serie - $epRef");
					if ($sth->fetch()->[0]) 
					{
						if ($verbose >= 1){print "$serie - $epRef already exists\n";}
					}
					else
					{
						# Add episode
						$title =~ s/\'/ /g;
						my $episodeInfos = "\'$serie - $epRef\', \'$serie\', \'$epRef\', \'$title\', \'\', \'false\', \'false\'";
						if ($verbose >= 1){print "$episodeInfos\n";}
						$dbh->do("INSERT INTO Episodes VALUES($episodeInfos)");
					}
					$sth->finish();
					$dbh->disconnect();
				}
			}
			$_ = $_."\t\t\t\t\t</div>\n";
			$_ = $_."\t\t\t\t</div>\n";
		}
	}
	if ($_ =~ /<date>/)
	{
		my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
		my @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
		$min = sprintf("%02d", $min);
		my $date = "$days[$wday] $mday $months[$mon] @ $hour:$min \n";
		$_ =~ s/<date>/$date/;
	}
	push (@html, $_);
}

# Output updated html page
open $HTML, '>', $outputHtmlPage or die "Cannot open output html file: $outputHtmlPage\n";
print $HTML @html;
close $HTML;

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
