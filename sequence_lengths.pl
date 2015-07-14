#!/usr/bin/perl
# This program goes through a list of sequences and prints off their
# lengths.


use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;


if (scalar @ARGV < 1) {
    die "Usage: sequence_lengths.pl <sequence file>\n";
}

my $seqin = Bio::SeqIO->new(-file => shift(@ARGV));
while (my $seq = $seqin->next_seq) {
    my $id = $seq->id;
    my $len = $seq->length;

    print "$id: $len nt\n";
}




