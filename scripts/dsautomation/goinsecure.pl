#!/usr/bin/perl 

use strict;
use warnings;

my @delfiles = glob('/tmp/*.DEL');
foreach my $file (@delfiles) {
    print STDERR "Working on $file\n";

    open(my $fh_in, "<", $file) or die "Can't open $file: $!";
    my $line = readline($fh_in);
    print STDERR "Found domain: $line\n";
    close($fh_in);
    rename $file, $file.".done";     # we worked through the file, remove it from queue

    # get name name and value of the first ds record
    my $action = "DELETE";
    my $name = $line;
    $name =~ s/\R//;
       
    # AWS requires to set in the current data to delete it.
    my $DSdata = `aws route53 list-resource-record-sets --hosted-zone-id Z02099872PWMNFHNH52LL --query "ResourceRecordSets[?Name == 'grp1.cologne.te-labs.training.']" | jq '.[] | select(.Type == "DS")'`;

    # if no DS records were found jump to next file
    if (!defined $DSdata || $DSdata  eq '') {
        print STDERR "No DS records found for $name\n";
        next;
    }

    # write aws data
    open(my $fh_out, ">", $file.".TMP") or die "Can't open $file.TMP: $!";
    print $fh_out <<EOF;
{ 
    "Comment": "$action DS records for $name",
    "Changes": [
        {
            "Action": "$action",
            "ResourceRecordSet": 
EOF
    print $fh_out $DSdata;
    print $fh_out <<EOF;
        }
    ]
}
EOF
    close($fh_out);
    rename $file.".TMP", $file.".AWS";

    # done with this file
    print STDERR "DONE file $file\n";
}
