#!/usr/bin/perl 

use strict;
use warnings;

my @dsfiles = glob('/tmp/*.DS');
foreach my $file (@dsfiles) {
    print STDERR "Working on $file\n";

    my @ds = ();

    open(my $fh_in, "<", $file) or die "Can't open $file: $!";
    while (my $line = readline($fh_in)) {
        if ($line =~ m/^\s*(\S+\s+\d+\s+IN\s+DS\s+\d+\s+\d+\s+\d+[0-9A-Za-z ]+)\s*$/) {
            print STDERR "DS record found.\n";
            push @ds, $1;
        }
    }
    close($fh_in);
    rename $file, $file.".done";     # we worked through the file, remove it from queue

    # if no DS records were found jump to next file
    if (scalar(@ds) == 0) {
        print STDERR "No DS records in $file found.\n";
        next;
    }

    # get name name and value of the first ds record
    $ds[0] =~ m/(\S+)/;
    my $name = $1;
    my $action = "UPSERT";

    # write aws data
    open(my $fh_out, ">", $file.".TMP") or die "Can't open $file.TMP: $!";
    print $fh_out <<EOF;
{ 
    "Comment": "$action DS records for $name",
    "Changes": [
        {
            "Action": "$action",
            "ResourceRecordSet": {
                "Name": "$name",
                "Type": "DS",
                "TTL":300 ,
                "ResourceRecords": [
EOF
    for(my $i=0; $i<scalar(@ds); $i++) {
        $ds[$i] =~ m/\S+\s+\d+\s+IN\s+DS\s+(\d+\s+\d+\s+\d+[0-9A-Za-z ]+)/;
        my $value = $1;
        print $fh_out <<EOF;
                    {
                        "Value": "$value"
                    }
EOF
            print $fh_out ",\n" if $i+1 < scalar(@ds); 
    }
    print $fh_out <<EOF;
                ]
            }
        }
    ]
}
EOF
    close($fh_out);
    rename $file.".TMP", $file.".AWS";

    # done with this file
    print STDERR "DONE file $file\n";
}
