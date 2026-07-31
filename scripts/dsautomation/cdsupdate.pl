#!/usr/bin/perl 

use strict;
use warnings;
use File::Temp qw(tempfile);

if (@ARGV != 2) {
    die "Usage: $0 <domain> <#networks>\n";
}

my $DOMAIN   = $ARGV[0];
my $NETWORKS = $ARGV[1];

my $dns_server = '100.64.0.54';
my $tsig_key   = 'hmac-sha256:nsupdate.key:86TjST9U6vQz07LCzet/EZ4cVoL5A4CsX92uJIQbWsQ=';

for(my $grp=1; $grp<=$NETWORKS; $grp++) {
    my @cds = ();
    my $digraw = `dig \@100.64.0.53 grp$grp.$DOMAIN. cds +noall +answer`;
    foreach my $line (split /\n/, $digraw) {
        if ($line =~ m/^\s*(\S+\s+\d+\s+IN\s+CDS\s+\d+\s+\d+\s+\d+[0-9A-Za-z ]+)\s*$/) {
            print STDERR "GETCDS: CDS record found for grp$grp.$DOMAIN.\n";
            push @cds, $1;
        }
    }

    # No output, otherwise every group will be logged every minute.
    next if scalar(@cds) == 0;

    # check if this is a CDS delete record
    if ($cds[0]=~m/^\s*\S+\s+\d+\s+IN\s+CDS\s+0+\s+0+\s+0/) {
        my ($fh_tmp, $tmpname) = tempfile();
        open(my $fh_out, ">", $tmpname) or die "Can't open $tmpname: $!";
        print $fh_out "grp$grp.$DOMAIN\n";
        close($fh_out);
        rename $tmpname, $tmpname.".DEL";
        print STDERR "CDSUPDATE: grp$grp.$DOMAIN going insecure\n";
        next;
    }

    # create a temporary file for nsupdate commands
    my ($fh_tmp, $tmpname) = tempfile();

    # write nsupdate commands to the temporary file
    print $fh_tmp "server $dns_server\n";
    print $fh_tmp "zone $DOMAIN\n";
    print $fh_tmp "update delete grp$grp.$DOMAIN. DS\n";
    for my $rr (@cds) {
        $rr =~ m/^\S+\s+\d*\s*IN\s+CDS\s+(\d+\s+\d+\s+\d+[0-9A-Za-z ]+)$/;
        my $value = $1;
        print $fh_tmp "update add grp$grp.$DOMAIN. 30 DS $value\n";
    }
    print $fh_tmp "send\n";
    close($fh_tmp);

    # run nsupdate with the temporary file
    my $cmd = "nsupdate -y $tsig_key $tmpname";
    my $rc = system($cmd);
    if ($rc != 0) {
        die "CDSUPDATE: nsupdate failed for grp$grp.$DOMAIN., rc=$rc";
    } else {
        print STDERR "CDSUPDATE: CDS for grp$grp.$DOMAIN. updated in zone $DOMAIN\n";
    }

    print STDERR "CDSUPDATE: DONE file grp$grp.$DOMAIN.\n";
}
