#!/usr/bin/perl
# This program converts an alignment from ClustalW to FASTA.


use strict;
use warnings;
use Bio::Seq;
use Bio::AlignIO;
use Bio::SimpleAlign;


my $infile = $ARGV[0];
my $outfile = $ARGV[1];

if (scalar @ARGV != 2)
{
    die "Format: clustalw_to_fasta.pl <input_alignment.aln> <output_alignment.fa>\n";
}

my $alignin = Bio::AlignIO->new(-file => $infile,
                                -format => 'clustalw');
my $alignout = Bio::AlignIO->new(-file => ">$outfile",
                                 -format => 'fasta');

my $aln_old = $alignin->next_aln();
my $aln_new = Bio::SimpleAlign->new();


foreach my $seqobj ($aln_old->each_seq())
{
    $aln_new->add_seq($seqobj);
}

$alignout->write_aln($aln_new);

