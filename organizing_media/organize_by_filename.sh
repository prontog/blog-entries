#!/usr/bin/env bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]... DIR...
Script that recursively moves files from DIRs into the current working dir in
subdirs with format YEAR/MONTH (i.e 2019/10) by default. It only moves files containing
a date in the filename.

Options:
  -d        create dir for each day using the format YYYY_MM_DD
  -h        display this help text and exit

EOF
  exit 1
}
# Print an error message
error() {
	echo "${0##*/}: $*" >&2
	exit 1
}

DATE_DIR=
while getopts "hd" option
do
	case $option in
        d) DATE_DIR=true;;
		h) usage;;
		*) usage;;
	esac
done
shift $(( $OPTIND - 1 ))

for DIR in $@; do
    if [[ -z $DIR ]]; then
    	error DIR cannot be empty
    fi

    if [[ ! -d $DIR ]]; then
        echo Skipping "'$DIR'". Not a dir  >&2
        continue
    fi

    find "$DIR" -type f | while read f; do
    	printf "%s;" "$f"
    	echo $f | sed -r 's/.*[^0-9](20[0-9]{2})([0-9]{2})([0-9]{2})[^0-9]*/\1;\2;\3/'
    	printf "\n"
    done | sed -u '/^$/d' | while IFS=';' read f y m d; do
        if [[ -z $y ]]; then
            echo "Skipping (Year is empty): $f" >&2
            continue
        fi
        if [[ -z $m ]]; then
            echo "Skipping (Month is empty): $f" >&2
            continue
        fi

        DIR_PATH=./$y/$m
        if [[ $DATE_DIR == true ]] && [[ -n $d ]]; then
            DIR_PATH=$DIR_PATH/${y}_${m}_${d}
        fi
    	echo "Moving: $f" >&2
    	mkdir -p $DIR_PATH
    	mv -n "$f" $DIR_PATH
    done
done
