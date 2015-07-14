#!/usr/bin/perl


use strict;
use warnings;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use Statistics::R;
use Tie::File;


my ($pathInit, $seq, $shape);
if (scalar(@ARGV) < 2)
{
    die "Correct usage: structure_predicion.pl <output_dir> <.seq file> <.shape file>";
}
$pathInit = $ARGV[0];
$seq = $ARGV[1];

my $shapeString = '';
if (defined $ARGV[2])
{
    $shape = $ARGV[2];
    $shapeString = " --SHAPE $shape";
}

#my @seqRange = &coordinates($seq);

# make partition functions and associated files
make_path($pathInit);
my $partitionBase = 'partition.pfs';
my $partitionFile = $pathInit . '/' . $partitionBase;
my $ctFile = $pathInit . '/probable_pairs.ct';
my $probsFile = $pathInit . '/probabilities.txt';
my $probsFilePrecursor = $pathInit . '/probabilities_precursor.txt';

my $baseHelix = $pathInit . '/base_helix.helix';
my $probsHelix = $pathInit . '/probs_helix.helix';
my $mfeStruct = $pathInit . '/mfe.ct';
my $probPairVienna = $pathInit . '/probable_pairs.vienna';
my $mfeVienna = $pathInit . '/mfe.vienna';

# run RNAstructure programs
system("fold $seq $mfeStruct --MFE" . $shapeString);
system("partition $seq $partitionFile" . $shapeString);
system("ProbablePair $partitionFile $ctFile -t 0.5");
system("ProbabilityPlot $partitionFile $probsFilePrecursor -t");

#if (@seqRange)
#{
#    &adjustCT($mfeStruct, $seqRange[0]);
#    &adjustCT($ctFile, $seqRange[0]);
#}


# make helix file and add probabilities column
# intention: to get helix file that includes base pairing probabilities
system("tail -n +2 $probsFilePrecursor >$probsFile");

# kind of a roundabout way of getting the sequence length
my $seqLength = `head -n 1 $probsFilePrecursor`;
chomp($seqLength);
#print $seqLength . "\n";
#$seqList{$seqName}{'length'} = $seqLength;

# Make a .helix file with probabilities (RNA structure format for R4RNA)
my $R = Statistics::R->new();
$R->run("library(R4RNA)");
$R->run("struct = expandHelix(readConnect('$ctFile'))",
        "writeHelix(struct, file='$baseHelix')",
        "partition = read.delim('$probsFile')",
        'partition$Probability = 10^(-partition[,3])',
       );

## change coordinates
#if (@seqRange)
#{
#    $R->run("modBy = " . $seqRange[0] . " - 1",
#            'partition$i = partition$i + modBy',
#            'partition$j = partition$j + modBy',
#           );
#}

$R->run("write.table(partition, file='$probsFile', sep='\t', row.names=FALSE, quote=FALSE)");


system("incorporate_probabilities.pl $baseHelix $probsHelix $probsFile");
unlink($baseHelix);
#unlink($probsFilePrecursor);

    
# plot probable pairs
my $probPairPdf = $pathInit . '/structures.pdf';

$R->run("pdf('$probPairPdf')",
        "helix = expandHelix(readHelix('$probsHelix'))",
        'helix$col = colourByValue(helix, breaks=c(.5,.7,.9,.99,1),' .
            'cols=c("gold","orange","red","brown"))',
        "seqLength = attr(helix, 'length')",
        "blankPlot(width=seqLength, top=seqLength/2, bottom=0)",
        "plotHelix(helix, line=TRUE, arrow=TRUE, add=TRUE)",
        'legend(seqLength/2, legend=attr(helix$col, "legend"),' . 
            'fill=attr(helix$col, "fill"),inset=.05, bty="n", border=NA,' .
            'title="Probability", cex=.75)',
        "text(seqLength/2, seqLength/2 + 15, 'Probable pairs structure', " .
            "adj=c(0.5, 0), cex=1.25)",
        "write(helixToVienna(helix), '$probPairVienna')");

# plot SHAPE data on top of probable pairs
if ($shapeString)
{
    $R->run("shapeFile = '$shape'",
            "shapeData = read.delim(shapeFile, header=FALSE)",
            "shapeVals = shapeData[,2]",
            "invalid = which(shapeVals < -500)",
            "shapeVals[invalid] = 0",
            
            "lines(shapeVals*10)",
            "points(invalid, shapeVals[invalid], col='green', pch=8)",
            
            "legend(seqLength, seqLength/2, xjust=1,inset=.05, " .
                "legend=c('SHAPE reactivity','No SHAPE data'), " .
                "lty=c(1,0), " .
                "pch=c(NA, 8), " .
                "col=c('black', 'green'), " .
                "bty='n', cex=.75, merge=TRUE)");
}

# plot MFE
$R->run("mfeHelix = expandHelix(readConnect('$mfeStruct'))",
        'mfeHelix$col = colourByCount(mfeHelix, "slateblue")',
        'blankPlot(width=seqLength, top=seqLength/2, bottom=0)',
        'plotHelix(mfeHelix, line=TRUE, arrow=TRUE, add=TRUE)',
        "text(seqLength/2, seqLength/2 + 15, 'Minimum free energy structure', " .
            "adj=c(0.5, 0), cex=1.25)",
        "write(helixToVienna(mfeHelix), '$mfeVienna')");

# close file
$R->run("dev.off()");


# change coordinates of CT file
sub adjustCT
{
    my ($ctFile, $start) = @_;
    my $modBy = $start - 1;
    tie my @ctlines, 'Tie::File', $ctFile or die $!;
    
    LINES:
    foreach my $line (@ctlines)
    {
        next LINES if $line eq $ctlines[0];
        
        my ($whitespace, $index, $base, $minus1, $plus1, $paired, $natnum) =
            split(/\s+/, $line);
        $index += $modBy;
        $minus1 += $modBy if $minus1;
        $plus1 += $modBy if $plus1;
        $paired += $modBy if $paired;
        
        $line = join("\t", $index, $base, $minus1, $plus1, $paired, $natnum);
    }
}



# Are there coordinates in the .SEQ file?
sub coordinates
{
    my $seqfile = shift;
    open SEQFILE, '<', $seqfile or die $!;
    while (<SEQFILE>)
    {
        if (/^;RANGE:(\d+)-(\d+)/)
        {
            my $start = $1;
            my $end = $2;
            
            return($start, $end);
        }
    }
    
    return ();
}




