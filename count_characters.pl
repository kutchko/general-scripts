#!/usr/bin/perl
# Count the number of characters in a file.
# Does not count newlines.


use strict;
use warnings;


my %characters;
while (<>)
{
    chomp;
    my @chars = split(//);
    
    foreach my $char (@chars)
    {
        $characters{$char}++;
    }
}


foreach my $char (sort keys %characters)
{
    print $characters{$char} . "\t" . $char . "\n";
}


