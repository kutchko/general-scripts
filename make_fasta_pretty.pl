#!/usr/bin/perl
# This program reads in a FASTA file with BioPerl and then prints
# it to another file, reformatted.


use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;


if (@ARGV < 2) {
    die "Usage: make_fasta_pretty.pl <in.fa> <out.fa>\n";
}

my ($inFile, $outFile) = @ARGV;
my $fastaIn = Bio::SeqIO->new(-file => $inFile,
                              -format => 'fasta');
my $fastaOut = Bio::SeqIO->new(-file => '>' . $outFile,
                               -format => 'fasta');

while (my $seqObj = $fastaIn->next_seq) {
    $fastaOut->write_seq($seqObj);
}


