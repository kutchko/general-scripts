#!/usr/bin/perl
# This program makes daily backups of all ZFS filesystems under
# /home.

use strict;
use warnings;
use Time::Piece;

#my $date = localtime->strftime('%Y-%m-%d');
my $date = localtime;


# list ZFS filesystems and make backups of home directories
my @zfsList = `zfs list -H`;
foreach (@zfsList)
{
    my ($name) = split(/\s+/);
    next if $name !~ m!^thrace/home!;
    my $snapshot = $name . "@" . $date->ymd;
    my $command = "zfs snapshot $snapshot";
    print $command . "\n";
    system($command);
}


# remove ZFS filesystems older than two weeks
my @snapshots = `zfs list -H -t snapshot`;
foreach my $snapshot (@snapshots)
{
    print $snapshot;
    my @line = split(/\s+/, $snapshot);
    my $name = $line[0];

    if ($name =~ m!^thrace/home.*@([\w\-]+)$!)
    {
        my $oldTime = $1;

        my $oldt = Time::Piece->strptime($oldTime, '%Y-%m-%d');
        my $difference = $date - $oldt;
        my $days = $difference->days;

        if ($days > 14)  # greater than two weeks old
        {
            my $command = "zfs destroy $name";
            print $command . "\n";
            system($command);
        }
    }


}





