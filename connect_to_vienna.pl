#!/usr/bin/perl
# This program takes a CT RNA structure file as input and outputs
# a vienna structure.
# Requires R, the Statistics::R package for Perl, and the R4RNA
# package for R.


use strict;
use warnings;
use Statistics::R;


if (! defined $ARGV[0])
{
    die "Usage: connect_to_vienna.pl <ct_file>\n";
}

my $R = Statistics::R->new;
$R->run('library(R4RNA)');

my $file = $ARGV[0];
$R->run("helix = expandHelix(readConnect('$file'))");
$R->run("vienna = helixToVienna(helix)");
my $vienna = $R->get('vienna');

print $vienna . "\n";

