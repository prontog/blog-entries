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
		print $1, $2, $3, $4, $5 
	}' $f > $f.temp
	
	mv $f.temp $f
done

# Replace Reserved field with the specific fields.
for f in $@; do
	sed -i '/^Reserved/c\
NotUsed,Long,1,Alpha,1\
Protocol,Long,1,Alpha,1\
ServerId,Long,1,Alpha,1\
ClientId,Long,1,Alpha,1' $f
done

# Add NUL field to all messages types from COMMS because it appends a NUL 
# character at the end of the DATA segment.
for f in {C,T}?_spec.csv; do
	echo "NUL,Long,1,Alpha,1" >> $f
done 

# Rename 5th column from 'Len' to 'Field Len'. It better not to have multiple 
# columns with the same name.
for f in $@; do
	sed -i 's/,Len$/,Field Len/' $f
done

# Fill Len for fields of type Long. These are empty in the documentation.
for f in $@; do
	sed -i 's/,Long,,/,Long,1,/' $f
done

# Fill Len for DSSMessage fields. These are variable length specified in the 'Length' field.
for f in $@; do
	sed -i 's/^DSSMessage,String,,/DSSMessage,String,Length,/' $f
done
