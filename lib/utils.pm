# Script to automatically download series subtitles from Addic7ed
#!/usr/bin/perl

package utils;	

use LWP::Simple;
use strict;
use Data::Dumper;

require Exporter;
my @ISA = qw/Exporter/;
my @EXPORT = qw/GetInfos testSubFile doesTableExist createTable insertDatas/;

sub insertData
{
	my ($verbose, $dbh, $tableName, $idValue, $id, $values) = @_;
	# Query to check if the data already exists
	my $query = "SELECT COUNT(*) FROM $tableName WHERE $idValue=?";
	if ($verbose >= 2){print "$query\n";}
	my $sth = $dbh->prepare($query);
	$sth->execute("$id");
	if ($sth->fetch()->[0]) 
	{
		if ($verbose >= 1){print "$id already exists\n";}
	}
	else
	{
		# add data
		$dbh->do("INSERT INTO $tableName VALUES($values)");
	}
	$sth->finish();
}

sub createTable
{
	my ($verbose, $dbh, $tableName, $tableValues) = @_;
	my $exists = doesTableExist($dbh, $tableName);
	if ($exists == 1)
	{
		if ($verbose >= 1){print ("Table \"$tableName\" already exists\n");}
		return 0;
	}
	
	if ($verbose >= 1){print ("\"$tableName\" table does not exists. Creating one.\n");}
	$dbh->do("DROP TABLE IF EXISTS $tableName");
	$dbh->do("CREATE TABLE $tableName($tableValues)");
}

sub doesTableExist 
{
    my ($dbh, $table_name) = @_;
	my $sth = $dbh->prepare("SELECT name FROM sqlite_master WHERE type=\'table\' AND name=\'$table_name\';");
    $sth->execute();
	my @info = $sth->fetchrow_array;
    my $exists = scalar @info;
	# print "Table \"$table_name\" exists: $exists\n";
	return $exists;
}

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
	
	# manage big bang theory season 10
	if ($file =~ /big/i and $file =~ /bang/i and $file =~ /theory/i and $file =~ /[^\w\(](\d{4})[^\d\)]/)
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