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
my $downloadsListFile = "";
my $verbose = 0;
my $downloadLogFile = "";
my $unseenLogFile = "";
my $outDirectory = "";
my $downloadDirectory = "";
my $htmlPage = "";
my $outputHtmlPage = "";
my $sendMail = 0;
my $betaSeriesKey = "";
my $betaSeriesLogin = "";
my $betaSeriesPassword = "";
my $bannersPath = "";

# Database variables
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
	    if ($_ =~ /downloadsListFile=(.*\.list)/)
	    {
		    $downloadsListFile = $1;
    	}
		elsif ($_ =~ /outDirectory=(.*)$/)
		{
			$outDirectory = $1;
		}
		elsif ($_ =~ /inDirectory=(.*)$/)
		{
			$downloadDirectory = $1;
		}
		elsif ($_ =~ /downloadLogFile=(.*)$/)
		{
			$downloadLogFile = $1;
		}
		elsif ($_ =~ /unseenLogFile=(.*)$/)
		{
			$unseenLogFile = $1;
		}
		elsif ($_ =~ /htmlPage=(.*)$/)
		{
			$htmlPage = $1;
		}
		elsif ($_ =~ /outputHtmlPage=(.*)$/)
		{
			$outputHtmlPage = $1;
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
		elsif ($_ =~ /bannersPath=(.*)$/)
		{
			$bannersPath = $1;
		}
		elsif ($_ =~ /tabletDatabasePath=(.*)$/)
		{
			$tabletDatabasePath = $1;
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
	# Print BetaSeries infos
	print "Downloads file list: $downloadsListFile\n";
	print "Unseen log file: $unseenLogFile\n";
	print "Download log file: $downloadLogFile\n";	
	print "Output directory: $outDirectory\n";
	print "Download directory: $downloadDirectory\n";
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


# Get episodes to download
my $token = &betaSeries::authentification($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword);
my @episodeTosee = &betaSeries::getEpisodesToSee($verbose, $token, $betaSeriesKey);
# print Dumper @episodeTosee;
 
# Open downloads file list
open my $LIST, '<', $downloadsListFile or die "Cannot open download list file: $downloadsListFile\n";
my @list = <$LIST>;
close $LIST;
my $episode = "";
my $serie = "";
my $epNumber = "";
my %status = ();

foreach (@list)
{
	if ($_ ne "\n")	
	{
		$episode = $_;
		chomp($episode);
		$episode = lc($episode);
		# Specific for Marvel's agents of S.H.I.E.L.D.
		$episode =~ s/marvel\'s/marvel/i;
		# Specific for DC's legends of tomorrow
		$episode =~ s/dc's/dc/i;	
		# Specific for Mr Robot
		$episode =~ s/mr\./mr/i;		
		# Specific for the blacklist: redemption
		$episode =~ s/blacklist: redemption/blacklist redemption/i;			
		# Remove 0 if season less than 10
		if ($episode =~ /(.*) - s(\d+)e(\d+)/i)
		{
			my $ep = 0 + $2;
			$episode = "$1 - s$ep"."e$3";
		}
		if ($verbose >=1) {print "$episode\n";}
		# Remove year if any
		if ($episode =~ /(.*) \(\d{4}\) - (.*)/i) {$serie = $1; $epNumber = $2;}
		elsif ($episode =~ /(.*) \(US\) - (.*)/i) {$serie = $1; $epNumber = $2;}
		elsif ($episode =~ /(.*) - (.*)/) {$serie = $1; $epNumber = $2;}
		# Specific for MacGyver (2016)
		if ($serie eq "macgyver") {$serie = $serie . "\ (2016\)";}
		$status{$serie}{$epNumber} = "<info>Download not launched yet<info>";
	}
	else {next;}
	# Open unseen logs
	open my $UNSEEN, '<', $unseenLogFile or die "Cannot open unseen log file: $unseenLogFile\n";
	my @unseen = <$UNSEEN>;
	close $UNSEEN;
	my $dateFound = 0;
	foreach (@unseen)
	{
		if ($dateFound == 0 && $_ =~ /$date/) 
		{
			$dateFound = 1;
			if ($verbose >=1) {print "$_";}
		}
		if ($dateFound == 1 && $_ =~ /(.*) --> (.*)/)
		{
			my $ep = lc ($1);
			my $epStatus = $2;
			
			# Remove " if any
			$ep =~ s/"//g;
			
			# Specific for Marvel's agents of S.H.I.E.L.D.
			$ep =~ s/marvel\'s/marvel/i;
			# Specific for DC's legends of tomorrow
			$ep =~ s/dc's/dc/i;				
			# Specific for Mr Robot
			$ep =~ s/mr\./mr/i;		
			# Specific for the blacklist: redemption
			$ep =~ s/blacklist: redemption/blacklist redemption/i;			

			if ($ep =~ /(.*) \(US\) - s(\d+)e(\d+)/i) {$ep = "$1 - s$2e$3";}
			if ($verbose >= 1) {print "$ep --> $epStatus\n";}
			# Remove 0 if season less than 10
			if ($ep =~ /(.*) - s(\d+)e(\d+)/i)
			{
				my $epNumber = 0 + $2;
				$ep = "$1 - s$epNumber"."e$3";
			}
			
			$ep =~ s/\(//g;$ep =~ s/\)//g;$episode =~ s/\(//g;$episode =~ s/\)//g;
			
			if ($ep =~ /$episode/i)
			{
				if ($epStatus eq "OK"){$status{$serie}{$epNumber} = "<info>Download launched<info>";}
				else {
					$status{$serie}{$epNumber} = "<danger>Failed to launch download<danger>";
					# Send email
					my $mailContent = "Download of $episode failed.\nPlease check.\n";
					my $email = Email::Simple->create(
					header => [
						From    => 'films.vouille@gmail.com',
						To      => 'thomas.fayoux@gmail.com',
						Subject => "Failed to download",
					],
					body => $mailContent,
					);					 
					# send the mail
					# sendmail( $email, {transport => $transport} );
				}
				last;
			}
		}
		else {next;}
	}
}

# Get files to be read
opendir (OUT, $outDirectory);
my @outDir = readdir(OUT);
close OUT;
foreach my $_ (@outDir)
{
	if ($_ =~ /(.*) - (.*)\.mp4/i || $_ =~ /(.*) - (.*)\.avi/i || $_ =~ /(.*) - (.*)\.mkv/i)
	{
		my $serie = lc($1);
		$status{$serie}{$2} = "<success>To be watched<success>";
	}
	else {next;}
}

# Check files from download directory
opendir (DOWN, $downloadDirectory);
my @downDir = readdir(DOWN);
close DOWN;
foreach my $file (@downDir)
{
	if ($file =~ /\.mp4/ or $file =~ /\.mkv/)
	{
		if ($verbose >=1) {print "$file\n";}
		my @infos = &utils::GetInfos($file, @tvShows);
		$infos[1] = $infos[1] + 0;
		if ($verbose >=1) {print "Looking for $infos[0] - s$infos[1]e$infos[2]\n";}
		$status{$infos[0]}{"s$infos[1]e$infos[2]"} = "<warning>No subtitles found<warning>";
	}
}

if ($verbose >= 1) {print Dumper %status;}
my @keys = sort keys %status;

my $episodes = 0;
foreach (@keys)
{
	my @eps = keys %{$status{$_}};
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
			my @episodes = sort keys %{$status{$serie}};
			my $nbEpisodes = $#episodes + 1;
			# Add line for the banner
			$_ = $_."\t\t\t\t\t\t<div class=\"row\">\n";
			$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-12\"><h3 id=\"serieTitle\"><img id=\"banniere\" class=\"img-responsive\" src=\"../images/".$serie.".jpg\" alt=\"".$serie." \(".$nbEpisodes."\)\"></h3></div>\n";
			$_ = $_."\t\t\t\t\t\t</div>\n";
			if ($verbose >= 1) {print "$serie \($nbEpisodes\)\n"; print Dumper @episodes;}
			foreach my $ep (@episodes)
			{
				my $title = "";
				my $epId = "";
				my $output = getTitle($verbose, $serie, $ep, @episodeTosee);
				if ($output ne ""){	($title, $epId) = split(/ - /, $output); }
				my $serieUnderscore = $serie;
				$serieUnderscore =~ s/ /_/g;
				$serieUnderscore =~ s/\(/\\\(/g;
				$serieUnderscore =~ s/\)/\\\)/g;
				
				my $epStatus = "";
				my $label = "";
				if ($status{$serie}{$ep} =~ /<(.*)>(.*)<.*>/)
				{
					$label = $1;
					$epStatus = $2;
				}
				
				# Print each episode
				$_ = $_."\t\t\t\t\t\t<div class=\"row\" id=\"episode\">\n";
				if ($status{$serie}{$ep} eq "<success>To be watched<success>")
				{
					$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-1\"><a href=\"..\/cgi-bin\/update.cgi?ep=".$serieUnderscore."-".$ep."-".$epId."\" class=\"glyphicon glyphicon-eye-open\" id=\"eye\"></a></div>\n";
				}
				else
				{
					$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-1\"><span class=\"glyphicon glyphicon-eye-open\" id=\"eye\"></span></div>\n";
				}
				$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-2\">".$ep.":</div>\n";
				$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-5\">".$title."</div>\n";
				$_ = $_."\t\t\t\t\t\t\t<div class=\"col-xs-4\"><span class=\"label label-".$label."\">".$epStatus."</span></div>\n";
				$_ = $_."\t\t\t\t\t\t</div>\n";
				
				#########################################################################################
				# Add episode available to be watched in the database
				if ($status{$serie}{$ep} eq "<success>To be watched<success>")
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
					$sth->execute("$serie - $ep");
					if ($sth->fetch()->[0]) 
					{
						if ($verbose >= 1){print "$serie - $ep already exists\n";}
					}
					else
					{
						# Add episode
						$title =~ s/\'/ /g;
						my $episodeInfos = "\'$serie - $ep\', \'$serie\', \'$ep\', \'$title\', \'\', \'false\', \'false\'";
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
	foreach my $serie (sort keys %status)
	{
		my @episodes = sort keys %{$status{$serie}};
		my $nbEpisodes = $#episodes + 1;
		$mailContent = $mailContent."$serie \($nbEpisodes\)\n";
		foreach my $episode (@episodes)
		{
			$status{$serie}{$episode} =~ s/<danger>//g; $status{$serie}{$episode} =~ s/<success>//g;
			$status{$serie}{$episode} =~ s/<warning>//g; $status{$serie}{$episode} =~ s/<info>//g;
			$mailContent = $mailContent."\t$episode --> $status{$serie}{$episode}\n";
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
