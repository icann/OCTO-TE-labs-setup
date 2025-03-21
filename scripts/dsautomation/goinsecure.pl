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
        
    # AWS requires to set in the current data to delete it.
    my $digresult  = `dig $name DS`;
    my @digresults = split /\n/, $digresult;

    my @ds = ();
    foreach my $line (@digresults) {
        continue if $line =~ m/^\s*$/; # skip empty lines
        continue if $line =~ m/^;/;    # skip comments
        if ($line =~ m/^\s*(\S+\s+\d+\s+IN\s+DS\s+\d+\s+\d+\s+\d+[0-9A-Za-z ]+)\s*$/) {
            print STDERR "DS record found.\n";
            push @ds, $1;
        }
    }

    # if no DS records were found jump to next file
    if (scalar(@ds) == 0) {
        print STDERR "No DS records found for $name\n";
        exit 0;
    }

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
        $ds[$i] =~ m/\S+\s+\d+\s+IN\s+(?:CDS|DS)\s+(\d+\s+\d+\s+\d+[0-9A-Za-z ]+)/;
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
