#!/usr/bin/perl -w

# set SHELLINABOX_ARGS="--no-beep -s /:shellinabox:shellinabox:/var/tmp:/usr/local/bin/dns-shell.pl" in /etc/defaults/shellinabox

use strict;

# liburi-query-perl

use URI;

my $filename = '/var/shellinabox/service-list.txt';

if (!defined($ENV{SHELLINABOX_URL})) {
        die "invoke with SHELLINABOX_URL env";
}

my $uri = URI->new($ENV{SHELLINABOX_URL});
my %query = $uri->query_form;

if ( $query{host} ) {
        my $host = $query{host};
        system("/usr/bin/ssh -l sysadm $host");
} else {
        print "choices:\n";

    if (open(my $fh, '<:encoding(UTF-8)', $filename)) {
      while (<$fh>) {
        print;
      }
    } else {
      warn "Could not open file '$filename' $!";
    }
}
