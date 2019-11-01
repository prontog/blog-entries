#!/usr/bin/env bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]... PHOTO_DIR...
Script that recursively moves photos from PHOTO_DIRs into the current working dir
in subdirs with format YYYY/MM (i.e 2019/10) by default.

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

for PHOTO_DIR in $@; do
    if [[ -z $PHOTO_DIR ]]; then
    	error PHOTO_DIR cannot be empty
    fi

    if [[ ! -d $PHOTO_DIR ]]; then
        echo Skipping "'$PHOTO_DIR'". Not a dir  >&2
        continue
    fi

    find $PHOTO_DIR -type f | while read f; do
    	printf "%s;" "$f"
    	#identify -verbose "$f" 2>/dev/null | sed -nr 's/.*Date.*Original: ([0-9]{4}):([0-9]{2}):([0-9]{2}).*/\1;\2;\3/p'
        exiftool -DateTimeOriginal "$f" | sed -nr 's/.*:.*([0-9]{4}):([0-9]{2}):([0-9]{2}).*/\1;\2;\3/p'
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
