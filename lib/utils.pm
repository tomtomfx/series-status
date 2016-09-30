# Script to automatically download series subtitles from Addic7ed
#!/usr/bin/perl

package utils;	

use LWP::Simple;
use strict;

require Exporter;
my @ISA = qw/Exporter/;
my @EXPORT = qw/GetInfos testSubFile/;


sub foundShow
{
	my ($file, $show) = @_;
	my @showWords = split(/ /, $show);
	foreach my $word (@showWords)	
	{
		if ($file !~ /$word/i)
		{
			return 0;
		}
	}
	return 1;
}

sub GetInfos
{
	my ($file, @shows) = @_;
	my $foundShow = 0;
	my @Infos;
	
	# manage shows with more than 9 seasons
	if ($file =~ /[^\w\(](\d{4})[^\d\)]/)
	{
		my $sn = substr($1, 0, 2);
		my $ep = substr($1, 2, 2);
		$ep = $sn."x".$ep;
		$file =~ s/$1/$ep/;
	}
	
	foreach my $show (@shows)
	{
		$foundShow = foundShow($file, $show);
		if ($foundShow == 1)
		{
			push(@Infos, $show);
			last;
		}
	}
	if ($foundShow == 1)
	{
		if ($file =~ /(\d+)x(\d+)/i)
		{
			push(@Infos, $1);
			push(@Infos, $2);
		}
		if ($file =~ /(\d+)e(\d+)/i)
		{
			push(@Infos, $1);
			push(@Infos, $2);
		}
		if ($file =~ /\W(\d{3})\D/ || $file =~ /[^\w\(](\d{4})[^\d\)]/)
		{
			(my $sn, my $ep) = split('', $1, 2);
			push(@Infos, $sn);
			push(@Infos, $ep);
		}
	}
	else
	{
		push(@Infos, "void");
	}
	return @Infos; 
}

sub testSubFile
{
	my ($file, $show, $season, $episode) = @_;
	my $foundShow = foundShow($file, $show);
	if ($foundShow == 1)
	{
		my $searchEpisode = $season . "x" . $episode;
		if ($file =~ /$searchEpisode/i)
		{
			return 1;
		}
		$searchEpisode = $season . "e" . $episode;
		if ($file =~ /$searchEpisode/i)
		{
			return 1;
		}		
	}
	return 0;
}
1;