#!/usr/bin/perl
# This program incorporates the probabilities from ProbablePairs
# into a helix file and makes a new file.


use strict;
use warnings;

if (scalar(@ARGV) != 3)
{
    print "perl incorporate_probabilities.pl <input_helix.helix> <output_helix.helix> <probabilities_file.txt>\n";
    print "# of arguments: " . $#ARGV . "\n";
    print "@ARGV\n";
    die;
}

my $helixFile = $ARGV[0];
my $newHelixFile = $ARGV[1];
my $probabilityFile = $ARGV[2];


open HELIX_IN, '<', $helixFile or die $!;
open HELIX_OUT, '>', $newHelixFile or die $!;
open PROBS, '<', $probabilityFile or die $!;


my $firstLine = <PROBS>;

my %probabilities;
while (<PROBS>)
{
    chomp;
    my ($nuc1, $nuc2, $logProb, $prob) = split(/\t/);
    $probabilities{$nuc1}{$nuc2} = $prob;
}
close PROBS;


while (<HELIX_IN>)
{
    my $line = $_;
    
    chomp;
    my ($nuc1, $nuc2, $length, $value) = split(/\t/);
    
    if (defined($value) && $value eq 'NA')
    {
        my $prob = $probabilities{$nuc1}{$nuc2};
        $line =~ s/NA/$prob/;
    }
    
    print HELIX_OUT $line;
}

close HELIX_IN;
close HELIX_OUT;

