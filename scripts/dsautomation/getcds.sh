#!/bin/bash

set -eou

DOMAIN=$1
NETWORKS=$2

#collect all CDS records, convert to DS records and save to temporary file
for grp in $(seq 1 $NETWORKS)
do
    # temporary file name
    TMP=$(mktemp).grp$grp

    # try to get DS records
    dig grp$grp.$DOMAIN. cds +noall +answer | grep -v -e '^;' | grep -v -e '^\s*$' | grep -E '\sIN\s+CDS\s' >> $TMP

    # if DS records were saved keep the file, otherwise remove 
    TMPSIZE=$(cat $TMP | wc -c)
    if [ $TMPSIZE -lt 10 ]; then
        echo "NO CDS records found for grp$grp";
        rm $tmp
    else
        echo "$(wc -l $TMP) CDS records found"
        mv $TMP $TMP.CDS
    fi
done

