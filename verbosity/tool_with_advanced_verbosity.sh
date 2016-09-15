#!/bin/bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]
Tool that...can be variably verbose!

Options:
  -h    display this help text and exit
  -v    make the operation more talkative
EOF
  exit 1
}

#### These functions can be moved to your bashrc file.
set_verbosity() {
	verbosity=$((verbosity + 1))
}
trace() {
	if [[ $verbosity -ge $1 ]]; then
		shift
		echo $*
	fi
}
####

while getopts "hv" option
do
	case $option in
		v) set_verbosity;;
		h|\?) usage;;
	esac
done

shift $(( $OPTIND - 1 ))

echo Starting...
trace 1 Verbosity level is $verbosity
trace 1 This should be verbose if verbosity level is at least 1
trace 2 This should be verbose if verbosity level is at least 2
trace 3 This should be verbose if verbosity level is at least 3
trace 4 This should be verbose if verbosity level is at least 4
echo ...finished!