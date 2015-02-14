#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use LWP::Simple;
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
	}
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
	print "\n";
}

# Start writing logs with date and time
my $time = localtime;
my $date = "";
if ($time =~ /(.*) \d*:\d*:\d*/) {$date = $1;}
if ($verbose >=1) {print "Looking for logs of $date\n";}

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
		# Remove 0 if saeson less than 10
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
		$status{$serie}{$epNumber} = "<strong>Download not launched yet<\/strong>";
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
		elsif ($dateFound == 1 && $_ =~ /(.*) --> (.*)/)
		{
			my $ep = lc ($1);
			my $epStatus = $2;
			# Specific for Marvel's agents of S.H.I.E.L.D.
			$ep =~ s/marvel\'s/marvel/i;	
			if ($ep =~ /(.*) \(US\) - s(\d+)e(\d+)/i) {$ep = "$1 - s$2e$3";}
			if ($verbose >= 1) {print "$ep --> $epStatus\n";}
			# Remove 0 if season less than 10
			if ($ep =~ /(.*) - s(\d+)e(\d+)/i)
			{
				my $epNumber = 0 + $2;
				$ep = "$1 - s$epNumber"."e$3";
			}
			if ($ep =~ /$episode/i)
			{
				if ($epStatus eq "OK"){$status{$serie}{$epNumber} = "<mark>Download launched<\/mark>";}
				else {$status{$serie}{$epNumber} = "<strong>Failed to launch download<\/strong>";}
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
	if ($_ =~ /(.*) - (.*)\.mp4/i)
	{
		my $serie = lc($1);
		$status{$serie}{$2} = "<mark>To be watched<\/mark>";
	}
	else {next;}
}

# Check files from download directory
opendir (DOWN, $downloadDirectory);
my @downDir = readdir(DOWN);
close DOWN;
foreach my $file (@downDir)
{
	if ($file =~ /\.mp4/)
	{
		if ($verbose >=1) {print "$file\n";}
		my @infos = &utils::GetInfos($file, @tvShows);
		$infos[1] = $infos[1] + 0;
		if ($verbose >=1) {print "Looking for $infos[0] - s$infos[1]e$infos[2]\n";}
		$status{$infos[0]}{"s$infos[1]e$infos[2]"} = "<strong>No subtitles found</strong>";
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
			$_ = $_."\t\t\t\t<h3 id=\"serie\"><img id=banniere src=\"images/".$serie.".jpg\" alt=\"".$serie." \(".$nbEpisodes."\)\"></h3>\n\t\t\t\t<table id=\"episodes\">\n";
			if ($verbose >= 1) {print "$serie \($nbEpisodes\)\n"; print Dumper @episodes;}
			foreach my $ep (@episodes)
			{
				my $output = getTitle($verbose, $serie, $ep, @episodeTosee);
				my ($title, $epId) = split(/ - /, $output);
				my $serieUnderscore = $serie;
				$serieUnderscore =~ s/ /_/g;
				if ($status{$serie}{$ep} eq "<mark>To be watched<\/mark>")
				{
					$_ = $_."\t\t\t\t\t<tr><td id=\"puce\"><a href=\"..\/cgi-bin\/update.cgi?ep=".$serieUnderscore."-".$ep."-".$epId."\"><img src=\"images/puce1.gif\"\/><\/td><td id=\"episodeNumber\">".$ep.":<\/td><td id=\"episodeTitle\">".$title."<\/td><td id=\"status\">".$status{$serie}{$ep}."<\/td><\/tr>\n";
				}
				else
				{
					$_ = $_."\t\t\t\t\t<tr><td id=\"puce\"><img src=\"images/puce1.gif\"\/><\/td><td id=\"episodeNumber\">".$ep.":<\/td><td id=\"episodeTitle\">".$title."<\/td><td id=\"status\">".$status{$serie}{$ep}."<\/td><\/tr>\n";
				}
			}
			$_ = $_."\t\t\t\t<\/table>\n";
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
	my $mailContent = "Bonjour Thomas,\nVoici le r�sum� \"s�ries\" du jour:\n\n";
	foreach my $serie (sort keys %status)
	{
		my @episodes = sort keys %{$status{$serie}};
		my $nbEpisodes = $#episodes + 1;
		$mailContent = $mailContent."$serie \($nbEpisodes\)\n";
		foreach my $episode (@episodes)
		{
			$status{$serie}{$episode} =~ s/<strong>//; $status{$serie}{$episode} =~ s/<\/strong>//;
			$status{$serie}{$episode} =~ s/<mark>//; $status{$serie}{$episode} =~ s/<\/mark>//;
			$mailContent = $mailContent."\t$episode --> $status{$serie}{$episode}\n";
		}
	}
	$mailContent = $mailContent."\nBonne soir�e.\n";
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

	# Create the transport. Using gmail for this example
	my $transport = Email::Sender::Transport::SMTP::TLS->new(
		host     => 'smtp.gmail.com',
		port     => 587,
		username => 'films.vouille@gmail.com',
		password => 'ctl1032!'
	);
	 
	# send the mail
	sendmail( $email, {transport => $transport} );
	if ($verbose >= 1) {print "Mail sent to thomas.fayoux\@gmail.com !\n";}
}
