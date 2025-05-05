#!/bin/bash

ZONEID=$1

for file in /tmp/*.AWS; do 
    if [ -f "$file" ]; then 
        echo "Submitting $file to AWS"
        aws route53 change-resource-record-sets --hosted-zone-id $ZONEID --change-batch file://$file
        mv $file $file.done
    fi
done