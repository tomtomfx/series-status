#!/usr/bin/perl

use strict;
use warnings;
use XML::Simple;
use Frontier::Client;
use Data::Dumper;

my $verbose = 0; 

foreach my $arg (@ARGV)
{
	if ($arg eq '-v') {$verbose = 1;}
	elsif ($arg eq '-vv'){$verbose = 2;}
	else {$verbose = 0;}
}

# Set server
my $xmlrpc = Frontier::Client->new('url' => 'http://192.168.1.5/RPC2');

# Get completed downloads
my @parameters = ("complete", "d.get_hash=");
my @torrents = $xmlrpc->call('d.multicall', @parameters);
if ($verbose >= 1) {print Dumper @torrents;}

# Remove finished
foreach (@{$torrents[0]})
{
	my @infos = $_;
	if ($verbose >= 1) {print "$infos[0][0]\n";}
	my @cmdParameters = ("$infos[0][0]");
	my $results = $xmlrpc->call('d.erase', @cmdParameters);
}