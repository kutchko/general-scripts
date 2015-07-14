#!/usr/bin/perl
# This program prints the chromosome sizes of a FASTA file, for
# IGVtools.


use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;

die "Error: no FASTA file specified!\n"
    if (! defined($ARGV[0]));

my $infile = $ARGV[0];

my $seqin = Bio::SeqIO->new(-file => $infile, -format => 'fasta');

while (my $seq = $seqin->next_seq)
{
    print $seq->id . "\t" . $seq->length . "\n";
}



