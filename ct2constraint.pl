#!/usr/bin/perl
# This program takes a CT file with a given offset and turns it into
# a constraint file for use with RNAstructure.


use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Data::Dumper;


my $offset;
GetOptions('offset=i' => \$offset)
    or die "Usage: ct2constraint.pl <input.ct> <output.con> --offset <num>\n";
if (! defined($offset)) {
    $offset = 1;
}


if (scalar(@ARGV) < 2) {
    die "Usage: ct2constraint.pl <input.ct> <output.con> --offset <num>\n";
}
my ($inCT, $outCon) = @ARGV;


# constraint parameters
my @constraintList = ('DS', 'SS', 'Mod', 'Pairs', 'FMN', 'Forbids');
my %constraints;
foreach my $con (@constraintList) {
    if ($con eq 'Pairs' || $con eq 'Forbids') {
        $constraints{$con} = [ "-1 -1" ];
    } else {
        $constraints{$con} = [ "-1" ];
    }
}

#print Dumper %constraints;

my @ssList;
my @pairList;


# read CT file
open CT, '<', $inCT or die $!;
my $firstline = <CT>;
while (my $line = <CT>) {
    $line =~ s/^\s+//;  # remove leading whitespace
    my ($pos, $nuc, undef, undef, $pair, undef) = split(/\s+/, $line);
    
    
    if ($pair == 0) {
        push(@ssList, $pos + $offset - 1);
    } elsif ($pos < $pair) {
        $pos += $offset - 1;
        $pair += $offset - 1;
        push(@pairList, "$pos $pair");
    }
}


# add CT data to constraint hash
unshift(@{$constraints{'SS'}}, @ssList);
unshift(@{$constraints{'Pairs'}}, @pairList);


# create constraints file
open OUTPUT, '>', $outCon or die $!;
foreach my $con (@constraintList) {
    print OUTPUT $con . "\n";
    foreach (@{$constraints{$con}}) {
        print OUTPUT $_ . "\n";
    }
}


