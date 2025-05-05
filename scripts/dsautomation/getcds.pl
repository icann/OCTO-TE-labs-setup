#!/usr/bin/perl 

use strict;
use warnings;

if (@ARGV != 2) {
    die "Usage: $0 <domain> <#networks>\n";
}

my $DOMAIN   = $ARGV[0];
my $NETWORKS = $ARGV[1];

for(my $grp=1; $grp<=$NETWORKS; $grp++) {
    my @ds = ();
    my $name = "grp$grp.";
    my $digraw = `dig grp$grp.$DOMAIN. cds +noall +answer`;
    foreach my $line (split /\n/, $digraw) {
        if ($line =~ m/^\s*(\S+\s+\d+\s+IN\s+CDS\s+(\d+)\s+\d+\s+\d+[0-9A-Za-z ]+)\s*$/) {
            print STDERR "CDS record found.\n";
            push @ds, $1;
            $name .= $2;
        }
    }
    next if scalar(@ds) == 0;
    if (-e "/tmp/$name.CDS.done") {
        print STDERR "CDS $name already processed\n";
        next;
    }
    open(my $fh_out, ">", "/tmp/$name") or die "Can't open /tmp/$name.CDS: $!";
    print $fh_out $digraw;
    close($fh_out);
    rename "/tmp/$name", "/tmp/$name.CDS";   
    print STDERR "$0: $name.CDS created.\n";
}