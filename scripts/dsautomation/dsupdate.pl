#!/usr/bin/perl 

use strict;
use warnings;
use File::Temp qw(tempfile);

if (@ARGV != 1) {
    die "Usage: $0 <domain>\n";
}

my $zone       = $ARGV[0];
my $dns_server = '100.64.0.54';
my $tsig_key   = 'hmac-sha256:nsupdate.key:86TjST9U6vQz07LCzet/EZ4cVoL5A4CsX92uJIQbWsQ=";

my @dsfiles = glob('/tmp/*.DS');
foreach my $file (@dsfiles) {
    print STDERR "DSUPDATE: Working on $file\n";

    my @ds = ();

    open(my $fh_in, "<", $file) or die "Can't open $file: $!";
    while (my $line = readline($fh_in)) {
        if ($line =~ m/^\s*(\S+\s+\d*\s*IN\s+DS\s+\d+\s+\d+\s+\d+[0-9A-Za-z ]+)\s*$/) {
            print STDERR "DSUPDATE: DS record found. $line\n";
            push @ds, $1;
        }
    }
    close($fh_in);
    rename $file, $file.".done";     # we worked through the file, remove it from queue

    # if no DS records were found jump to next file
    if (scalar(@ds) == 0) {
        print STDERR "DSUPDATE: No DS records in $file found.\n";
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
        $rr =~ m/^\S+\s+\d*\s*IN\s+DS\s+(\d+\s+\d+\s+\d+[0-9A-Za-z ]+)$/ or next;
        my $value = $1;
        print $fh_tmp "update add $name 30 DS $value\n";
    }

    print $fh_tmp "send\n";
    close($fh_tmp);

    # run nsupdate with the temporary file
    my $cmd = "nsupdate -k $tsig_key $tmpname";
    my $rc = system($cmd);
    if ($rc != 0) {
        die "DSUPDATE: nsupdate failed for $name, rc=$rc";
    } else {
        print STDERR "DSUPDATE: DS RR set for $name updated in zone $zone\n";
    }

    print STDERR "DSUPDATE: DONE file $file\n";
}
