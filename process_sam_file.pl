#!/usr/bin/perl
# This program creates sorted BAM files from a list of SAM files as input.


use strict;
use warnings;


my $samFile = $ARGV[0];

foreach my $samFile (@ARGV)
{
    my $root = '';
    if ($samFile =~ /^(.+)\.sam$/)
    {
        $root = $1;
    } else {
        warn "$samFile is unrecognized file format! (Should be *.sam)\n";
        next;
    }
    print "Processing $samFile...\n";

    my $bamFile = $root . ".bam";
    system("samtools view -bS $samFile > $bamFile");
    system("samtools sort $bamFile $root.sorted");
    unlink($bamFile);
    my $sortedFile = $root . ".sorted.bam";
    system("samtools index $sortedFile");

    print "Sorted file: $sortedFile\n";
    my $countFile = $root . "_counts.tdf";
}



