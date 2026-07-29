#!/usr/bin/perl 

use strict;
use warnings;

if (@ARGV != 1) {
    die "Usage: $0 <domain>\n";
}

my $zone       = $ARGV[0];

my @delfiles = glob('/tmp/*.DEL');
foreach my $file (@delfiles) {
    print STDERR "GOINSECURE: Working on $file\n";

    open(my $fh_in, "<", $file) or die "Can't open $file: $!";
    my $line = readline($fh_in);
    print STDERR "GOINSECURE: Found domain: $line\n";
    close($fh_in);
    rename $file, $file.".done";     # we worked through the file, remove it from queue

    # create a temporary file for nsupdate commands
    my ($fh_tmp, $tmpname) = tempfile();

    # write nsupdate commands to the temporary file
    print $fh_tmp "server $dns_server\n";
    print $fh_tmp "zone $zone\n";
    print $fh_tmp "update delete $name DS\n";
    print $fh_tmp "send\n";
    close($fh_tmp);

    # run nsupdate with the temporary file
    my $cmd = "nsupdate -k $tsig_key $tmpname";
    print STDERR "GOINSECURE: Running: $cmd\n";
    my $rc = system($cmd);

    if ($rc != 0) {
        die "GOINSECURE: nsupdate failed for $name, rc=$rc";
    }

    # done with this file
    print STDERR "GOINSECURE: DONE file $file\n";
}
