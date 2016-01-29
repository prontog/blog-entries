#!/bin/bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} MD_SPECS
Converts one or more mdtable files to csv format.
EOF
  exit 1
}

if [[ ! -f $1 ]]; then
    usage
fi

# Convert from markdown table to csv with | as a separator.
for f in $@; do
	sed '
	# Delete ** from the first line.
	s/\*//g
	# Delete lines that start with space. These
	# are multirow cells from Remarks column.
	/^[[:space:]]/d
	# Delete rows with |---.
	/^|---/d
	# Remove first | and trim.
	s/^|[[:space:]]*//
	# Remove final | and trim.
	s/[[:space:]]*|[[:space:]]*$//
	# Trim middle |.
	s/[[:space:]]*|[[:space:]]*/|/g
	# Delete empty rows.
	/^$/d' $f > ${f/$".mdtable"/.csv}
done
