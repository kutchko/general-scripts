#!/usr/bin/perl
# This program backs up my home directory onto the /backup volume.


use strict;
use warnings;
use Time::Piece;

my $date = localtime;


my $snapshot = "thrace/home/kutchko@" . $date->ymd;

my $cmd = "zfs send -v $snapshot | xz > /backup/kutchko_snapshot.img.xz";
print $cmd . "\n";
system($cmd);



