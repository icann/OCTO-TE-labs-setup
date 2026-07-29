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
            print STDERR "GETCDS: CDS record found.\n";
            push @ds, $1;
            $name .= $2;
        }
    }
    next if scalar(@ds) == 0;

    # check if this is a CDS delete record
    if ($ds[0]=~m/^\s*\S+\s+\d+\s+IN\s+CDS\s+0+\s+0+\s+0/) {
        open(my $fh_out, ">", $file.".TMP") or die "Can't open $file.TMP: $!";
        print $fh_out "$name\n";
        close($fh_out);
        rename $file.".TMP", $file.".DEL";
        print STDERR "GETCDS: $name going insecure\n";
        next;
    }

    # check if this CDS has already been processed
    if (-e "/tmp/$name.CDS.done") {
        print STDERR "CDS $name already processed\n";
        next;
    }

    # write CDS data to /tmp/$name.CDS
    open(my $fh_out, ">", "/tmp/$name") or die "Can't open /tmp/$name.CDS: $!";
    print $fh_out $digraw;
    close($fh_out);
    rename "/tmp/$name", "/tmp/$name.CDS";   
    print STDERR "GETCDS: $name.CDS created.\n";
}