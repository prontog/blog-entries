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

awk '
# Get the header containing the message type in parentheses.
/### / {
	header = $0
	match(header, /^### ([A-Z]{2}) /, results)
	messageType = results[1]
	if (messageType) {
		spec_file = sprintf("%s.mdtable", messageType)
		print "" > spec_file
	}
}
# Print the message table into a different file.
/^\| /,/^$/{
	if (messageType) {
		print >> spec_file
	}
	
	if ($0 ~ /^$/) {
		messageType = 0
	}
}
' $1
