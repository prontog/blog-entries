#!/usr/bin/env bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} PHOTO_DIR
Script that recursively moves photos from PHOTO_DIR into the current working dir
in subdirs with format YEAR/MONTH (i.e 2019/10)

EOF
  exit 1
}
# Print an error message
error() {
	echo "${0##*/}: $*" >&2
	exit 1
}

PHOTO_DIR=$1
if [[ ! -d $PHOTO_DIR ]]; then
	error PHOTO_DIR is not a directory [$PHOTO_DIR]
fi

find "$PHOTO_DIR" -type f | while read f; do
	printf "%s;" "$f"
	identify -verbose "$f" 2>/dev/null | sed -nr 's/.*Date.*Original: ([0-9]{4}):([0-9]{2}):([0-9]{2}).*/\1;\2/p'
	printf "\n"
done | sed -u '/^$/d' | while IFS=';' read f y m; do
	if ! [[ -f $f ]]; then
        echo "Skipping (Not a file): $f" >&2
        continue
    fi
    if [[ -z $y ]]; then
        echo "Skipping (Year is empty): $f" >&2
        continue
    fi
    if [[ -z $m ]]; then
        echo "Skipping (Month is empty): $f" >&2
        continue
    fi
	echo "Moving: $f" >&2
	mkdir -p ./$y/$m
	mv "$f" ./$y/$m
done
