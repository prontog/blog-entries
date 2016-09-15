#!/bin/bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]
Script that can get...verbose!

Options:
  -h    display this help text and exit
  -v    explain what is being done
EOF
  exit 1
}

#### These functions can be moved to your bashrc file
# Function that handles the verbosity option.
set_verbosity() {
	verbosity=1
}
# Function that echoes all passed arguments to stderr if verbosity is on.
trace() {
	[[ $verbosity -gt 0 ]] && echo $* >&2
}
####

tshark_stderr='2>/dev/null'
# Handle CLI options.
while getopts "hv" option
do
	case $option in
		v) set_verbosity
		   curl_verbosity=-v
		   tshark_stderr=
		;;
		h|\?) usage;;
	esac
done
shift $(( $OPTIND - 1 ))

# A simply trace message
trace [$(date +%T)] Start doing stuff...
# Enabling verbosity on another program.
# case 1: Just pass -v if verbosity is on.
curl $curl_verbosity https://duckduckgo.com > /dev/null
# case 2: Make a verbose-by-default program to shut up if 
# verbosity is off.
eval tshark -i 5 -c 10 $tshark_stderr > /dev/null
# Another trace message
trace [$(date +%T)] Finished!