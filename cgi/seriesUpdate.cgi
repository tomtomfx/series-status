#!/usr/bin/perl

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(standard);

system("perl \/home\/tom\/SubtitleManagement\/bin\/seriesStatus.pl 0");

print CGI::redirect("..\/series\/");
