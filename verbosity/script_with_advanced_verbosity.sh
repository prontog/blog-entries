#!/bin/bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]
Script that can be get...verbose and more verbose and then even more verbose!

Options:
  -h    display this help text and exit
  -v    make the operation more talkative. Multiple -v options increase 
        the verbosity.
EOF
  exit 1
}

#### These functions can be moved to your bashrc file:
# Handle the verbosity option. Use it in the `case` 
# statement handling the program options.
set_verbosity() {
	verbosity_level=$((verbosity_level + 1))
}

# Echo all passed arguments to stderr if verbosity is on. 
# If the first parameter is numeric then the message will 
# only be echoed if the verbosity level is >= to it (the 
# message level). Otherwise the message level will be 1.
trace() {
	local msg_level=$(($1 + 0))
	if [[ $msg_level -gt 0 ]]; then
		shift
	else
		msg_level=1
	fi
	
	verbosity_level=$(($verbosity_level + 0))
	
	if [[ $verbosity_level -ge $msg_level ]]; then
		echo $* >&2
	fi
}
####

# Handle CLI options
while getopts "hv" option
do
	case $option in
		v) set_verbosity;;
		h|\?) usage;;
	esac
done
shift $(( $OPTIND - 1 ))

# Start doing stuff
echo Starting...
trace 1 Verbosity level is $verbosity_level
trace 1 This should be verbose if verbosity level is at least 1
trace 2 This should be verbose if verbosity level is at least 2
trace 3 This should be verbose if verbosity level is at least 3
trace 4 This should be verbose if verbosity level is at least 4
trace This line has no trace level! Defaults to 1.
echo ...finished!