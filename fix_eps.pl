#!/usr/bin/perl
# This program converts a list of EPS files


use strict;
use warnings;
use Tie::File;
use File::Basename;
use File::Spec::Functions;
use File::Copy;


my @newEPS;

FILES:
foreach my $epsFile (@ARGV) {
    if ($epsFile !~ /\.eps$/) {
        warn "$epsFile does not end in .eps--skipping!\n";
        next FILES;
    }
    
    push(@newEPS, &fixEPS($epsFile));
}

my $pdfOut = 'eps_compiled.pdf';
my $epsList = join(' ', @newEPS);
my $PDFcmd = "gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dEPSCrop " .
    "-sOutputFile=$pdfOut " .
    "$epsList";
print $PDFcmd . "\n";
system($PDFcmd);


foreach my $fixedEPS (@newEPS) {
    unlink($fixedEPS);
}


sub fixEPS {
    my $epsFile = shift;
    
    my ($fileRoot, $directory, $suffix) = fileparse($epsFile, '.eps');
    my $newFile = catfile($directory, $fileRoot . '_fixed.eps');

    tie my @EPSlines, 'Tie::File', $epsFile or die $!;
    $EPSlines[0] = '%!PS-Adobe-3.0 EPSF-3.0';
    untie @EPSlines;

    my $cmd = "epstool --copy --bbox $epsFile $newFile";
    print $cmd . "\n";
    system($cmd);
    
    return($newFile);
}


