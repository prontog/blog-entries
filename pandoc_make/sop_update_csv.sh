#!/bin/bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} MD_SPEC
Converts an md spec into csv files. One per message type.
EOF
  exit 1
}

if [[ ! -f $1 ]]; then
    usage
fi

set -o errexit

# Remove Remark column and replace | with , as a separator. The Remark column 
# might contain characters that mess up the CSV parser.
for f in $@; do
	awk '
	BEGIN { 
		FS = "|"; 
		OFS = "," 
	} 
	{ 
		print $1, $2, $3, $4
	}' $f > $f.temp
	
	mv $f.temp $f
done
