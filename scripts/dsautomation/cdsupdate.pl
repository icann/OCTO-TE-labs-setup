#!/usr/bin/perl 

use strict;
use warnings;

if (@ARGV != 1) {
    die "Usage: $0 <domain>\n";
}

my $zone       = $ARGV[0];

my @dsfiles = glob('/tmp/*.CDS');
foreach my $file (@dsfiles) {
    print STDERR "CDSUPDATE: Working on $file\n";

    my @ds = ();

    open(my $fh_in, "<", $file) or die "Can't open $file: $!";
    while (my $line = readline($fh_in)) {
        if ($line =~ m/^\s*(\S+\s+\d+\s+IN\s+CDS\s+\d+\s+\d+\s+\d+[0-9A-Za-z ]+)\s*$/) {
            print STDERR "CDSUPDATE: CDS record found.\n";
            push @ds, $1;
        }
    }
    close($fh_in);
    rename $file, $file.".done";     # we worked through the file, remove it from queue

    # if no DS records were found jump to next file
    if (scalar(@ds) == 0) {
        print STDERR "CDSUPDATE: No CDS records in $file found.\n";
        next;
    }

    # get name name and value of the first ds record
    $ds[0] =~ m/(\S+)/;
    my $name = $1;

    # create a temporary file for nsupdate commands
    my ($fh_tmp, $tmpname) = tempfile();

    # write nsupdate commands to the temporary file
    print $fh_tmp "server $dns_server\n";
    print $fh_tmp "zone $zone\n";
    print $fh_tmp "update delete $name DS\n";
    for my $rr (@ds) {
        $rr =~ m/^\S+\s+\d*\s*IN\s+CDS\s+(\d+\s+\d+\s+\d+[0-9A-Za-z ]+)$/;
        my $value = $1;
        print $fh_tmp "update add $name $ttl DS $value\n";
    }
    print $fh_tmp "send\n";
    close($fh_tmp);

    # run nsupdate with the temporary file
    my $cmd = "nsupdate -k $tsig_key $tmpname";
    print STDERR "CDSUPDATE: Running: $cmd\n";
    my $rc = system($cmd);

    if ($rc != 0) {
        die "CDSUPDATE: nsupdate failed for $name, rc=$rc";
    }

    print STDERR "CDSUPDATE: DONE file $file\n";
}
