#!/bin/bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]
Tool that...can be verbose!

Options:
  -h    display this help text and exit
  -v    explain what is being done
EOF
  exit 1
}

#### These functions can be moved to your bashrc file.
set_verbosity() {
	verbosity=1
}
trace() {
	if [[ $verbosity > 0 ]]; then
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
trace Verbosity is on
echo ...finished!