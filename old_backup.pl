#!/usr/bin/perl


use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use Net::SFTP;
use Term::ReadKey;


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

# list of backup directories
my @backupList = ('RB1','RMRP','Presentations','Bioalgorithms','FTL','HeLa','HeLa2');

chdir or die $!;
chdir('Desktop') or die $!;
my $newMon = $mon+1;
if ($newMon < 10) { $newMon = "0$newMon"; }
if ($mday < 10) { $mday = "0$mday"; }
my $dateString = "RNA_backup_" . ($year+1900) . '-' . ($newMon) . '-' . $mday;
make_path($dateString) or die $!;

foreach my $dir (@backupList)
{
    make_path($dateString . '/' . $dir) or die $!;
    dircopy($dir,$dateString . '/' . $dir) or die $!;
}

my $tarFile = $dateString . '.tar.gz';
system("tar -czf $tarFile $dateString");

print "Password for kure.unc.edu: ";
ReadMode('noecho');
chomp(my $password = <STDIN>);
ReadMode(0);
print "\n";

my %args = ('user' => 'kutchko',
            'password' => $password);

eval {
    my $sftp = Net::SFTP->new('kure.unc.edu',%args);
    if ($sftp->put($tarFile,'ms/' . $tarFile)) {
        print "File backed up to mass storage successfully!\n";
    } else {
        print "Error backing up $tarFile!\n";
    }
};
warn $@ if $@;

unlink($tarFile);
remove_tree($dateString);

