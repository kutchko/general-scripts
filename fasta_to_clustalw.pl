#!/usr/bin/perl
# This program converts an alignment from FASTA to ClustalW.


use strict;
use warnings;
use Bio::Seq;
use Bio::AlignIO;
use Bio::SimpleAlign;


my $infile = $ARGV[0];
my $outfile = $ARGV[1];

if (scalar @ARGV != 2)
{
    die "Format: fasta_to_clustalw.pl <input_alignment.fa> <output_alignment.aln>\n";
}

my $alignin = Bio::AlignIO->new(-file => $infile,
                                -format => 'fasta');
my $alignout = Bio::AlignIO->new(-file => ">$outfile",
                                 -format => 'clustalw');

my $aln_old = $alignin->next_aln();
my $aln_new = Bio::SimpleAlign->new();


foreach my $seqobj ($aln_old->each_seq())
{
    $aln_new->add_seq($seqobj);
}

$alignout->write_aln($aln_new);

