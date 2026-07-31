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
    print $fh_tmp "update delete $line DS\n";
    print $fh_tmp "send\n";
    close($fh_tmp);

    # run nsupdate with the temporary file
    my $cmd = "nsupdate -k $tsig_key $tmpname";
    my $rc = system($cmd);
    if ($rc != 0) {
        die "GOINSECURE: nsupdate failed for $line, rc=$rc";
    } else {
        print STDERR "GOINSECURE: DS for $line removed from zone $zone\n";
    }

    # done with this file
    print STDERR "GOINSECURE: DONE file $file\n";
}
