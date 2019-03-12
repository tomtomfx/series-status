#!/usr/bin/perl

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(standard);

my $buffer, my $name, my $ep;
# Read in text
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
if ($ENV{'REQUEST_METHOD'} eq "GET")
{
	$buffer = $ENV{'QUERY_STRING'};
}
# Split information into name/value pairs
($name, $ep) = split(/=/, $buffer);

system("perl \/home\/tom\/SubtitleManagement\/bin\/episodeSeen.pl $ep");

print CGI::redirect("..\/series\/series.php");
