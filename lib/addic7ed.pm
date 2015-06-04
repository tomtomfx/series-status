# Script to automatically download series subtitles from Addic7ed
#!/usr/bin/perl

package addic7ed;	

use LWP::Simple;
use Sys::Hostname;
use strict;

require Exporter;
my @ISA = qw/Exporter/;
my @EXPORT = qw/downloadSubtitles/;

sub downloadSubtitles
{
	my $filename = $_[0]; 
	my $downloadDir = $_[1];
	my $logFile = $_[2]; 
	my $verbose = $_[3];

	# Open log file
	open (LOG, ">>", $logFile) or die "Cannot open $logFile";
	 
	# Remove unused info
	my @del = ("readnfo","extended","theatrical","limited","dc","rerip","dubbed","docu","unrated","festival","ac3","720p","1080p","HDTV");
	foreach (@del){$filename =~ s/\.$_//i;}

	# Remove file extension
	$filename =~ s/\.mp4//i; $filename =~ s/\.avi//i;
	
	# Specific for Rush
	$filename =~ s/\WUS\W/\./i;
	$filename =~ s/rush/rush 2014/i;
	
	# Manage US/UK and year tags
	$filename =~ s/(\W)US(\W)/$1\(US\)$2/i; 
	$filename =~ s/(\W)UK(\W)/$1\(UK\)$2/i; 
	
	if ($filename =~ /(2\d{3})/)
	{
		my $year = $1;
		$filename =~ s/2\d{3}/\($year\)/;
		# Specific for Castle
		$filename =~ s/Castle.*\(2\d{3}\)/Castle/i;
	}
	
	# Specific for Marvel's agents of S.H.I.E.L.D
	$filename =~ s/marvels/marvel's/i;
	$filename =~ s/marvel.s/marvel's/i;
	
	if ($verbose >= 2) {print "$filename\n";}
	
	my $show, my $season, my $episode;

	# Get show and episode info
	# show.s01e02.mp4
	if ($filename =~ /(.+)S(\d+)E(\d+)/i)
	{
		$show = $1; $season = $2; $episode = $3;
	} 
	# show.1x02.mp4
	elsif ($filename =~ /(.+)(\d+)x(\d+)/) 
	{
		$show = $1; $season = $2; $episode = $3; 
	}
	# show.102.mp4
	elsif ($filename =~ /(.+)\W(\d{3})\D/) 
	{
		$show = $1; 
		my $seasonEp = $2;
		($season, $episode) = split('', $seasonEp, 2);
		my $ep = "s".$season."e".$episode;
		$filename =~ s/$seasonEp/$ep/i;
	}
	else
	{
		my $host = hostname;
		my $time = localtime;
		print LOG "[$time] $host GetSubtitles ERROR \"No show, season or episode found\"\n";
		close LOG;
		return 0;
	}


	$show =~ s/\./_/g; $show =~ s/ /_/g; $show =~ s/_$//;

	# Specific for Marvel's agents of S.H.I.E.L.D
	$show =~ s/S_H_I_E_L_D/S\.H\.I\.E\.L\.D/i;
	# Specific for Daredevil
	if ($show =~ /daredevil/i) {$show = "Daredevil";}

	if ($verbose >= 2) {print "Show: $show, Season: $season, Episode: $episode\n";}
	my $download = tv($filename, $show, $season, $episode, $downloadDir, $verbose);

	# Close the log file
	close LOG;
}
	
sub tv 
{
		my $filename = $_[0];
		my $show = $_[1]; $show =~ s/ /_/g;
		my $episode = "s$_[2]e$_[3]";
		my $verbose = $_[5];
		my $time = localtime;
		my $host = hostname;
		if ($verbose >= 2) {print "http://www.addic7ed.com/serie/$show/$_[2]/$_[3]/x\n";}
		print LOG "[$time] $host GetSubtitles INFO \"$show - $episode\" Addic7ed=http://www.addic7ed.com/serie/$show/$_[2]/$_[3]/x\n";
		my @url = split("\n", get("http://www.addic7ed.com/serie/$show/$_[2]/$_[3]/x"));
		my $downloadDir = $_[4];
		#open (WEB, ">", "web.txt");
		
		my $versionFound = 0; my $version; my $usedVersion;
		my $languageFound = 0; 
		my $subNumber;
		my $subCompleted = 0;
		my $downloadAddressFound = 0; my $downloadAddress;
				
		foreach (@url) 
		{
			#print WEB "$_\n";
			if (($_ =~ /Version (.*),/i || $_ =~ /Should work with (.*)</i || $_ =~ /works with (.*)</i) && $versionFound == 0)
			{
				$version = $1;
				$languageFound = 0;
				$subCompleted = 0;
				
				if ($version =~ /,/ || $version=~ /and/i)
				{
					$version =~ s/ /,/g;
					$version =~ s/and/,/ig;
					$version =~ s/\./,/g;					
					my @versions = split(/,/, $version);
					foreach (@versions)
					{
						if ($_ eq "\(" | $_ eq "\)") {next;}
						if ($filename =~ /$_/i){$versionFound=1;$usedVersion=$_;}
						elsif ($_ =~ /(PROPER)/i || $_ =~ /(REPACK)/i)
						{
							my $versionType = $1;
							$_ =~ s/$versionType//;
							if ($filename =~ /$versionType/ && $filename =~ /$_/)
							{
								$versionFound=1;
								$usedVersion="$versionType-$version";
								if ($verbose >= 2) {print "Version: $versionType-$version\n";}
							}
						}
					}
				}
				elsif ($version =~ /(PROPER)/i || $version =~ /(REPACK)/i)
				{
					my $versionType = $1;
					$version =~ s/$versionType//;
					$version =~ s/ //g;
					if ($filename =~ /$versionType/ && $filename =~ /$version/)
					{
						$versionFound=1;
						$usedVersion="$versionType-$version";
						if ($verbose >= 2) {print "Version: $versionType-$version\n";}
					}
				}
				elsif ($filename =~ /$version/i){$versionFound=1;$usedVersion=$version;}
				next;
			}
			if ($versionFound && $_ =~ /saveFavorite\(([0-9]+)/) 
			{
				$subNumber = $1;
				$languageFound = 0;
				$subCompleted = 0;
				if ($_ =~ /English/)
				{
					if ($verbose >= 2) {print "Language found: $subNumber\n";}
					$languageFound = 1;
				}
				next;
			}
			if ($versionFound && $languageFound && $_ =~ /<b>Completed/)
			{
				$subCompleted = 1;
				if ($verbose >= 2) {print "Completed\n";}
				next;
			}
			if ($versionFound && $languageFound && $subCompleted && ($_ =~ /buttonDownload\" href=\"(\/original\/\d+\/\d+)\">/ || $_ =~ /buttonDownload\" href=\"(\/updated\/\d+\/\d+\/\d+)\"><strong>most updated/))
			{
				if ($verbose >= 2) {print "$1\n";}
				$downloadAddress = $1;
				$downloadAddressFound = 1;
				last;
			}
			if ($_ =~ /tabel95/){$versionFound = 0;}
		}
		if ($downloadAddressFound)
		{
			my $host = hostname;
			my $time = localtime;
			print LOG "[$time] $host GetSubtitles INFO \"$show - $episode\" Subtitle version: $usedVersion\n";
			# Download subtitle
			my $sub = "curl -s --referer http://www.addic7ed.com/ http://www.addic7ed.com$downloadAddress -o \"$downloadDir\/$filename.srt\"";
			$sub =~ s/\(//g;
			$sub =~ s/\)//g;
			if($verbose >= 1) {print "$sub\n";}
			system("$sub");
			
			return $downloadAddress;
		}
		#close WEB
}
1;