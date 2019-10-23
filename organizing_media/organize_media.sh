#!/usr/bin/env bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} MEDIA_DIR
Script that recursively moves audio/video files from MEDIA_DIR into the current
working dir in subdirs with format YEAR/MONTH (i.e 2019/10)

EOF
  exit 1
}
# Print an error message
error() {
	echo "${0##*/}: $*" >&2
	exit 1
}

MEDIA_DIR=$1
if [[ ! -d $MEDIA_DIR ]]; then
	error MEDIA_DIR is not a directory [$MEDIA_DIR]
fi

find "$MEDIA_DIR" -type f | while read f; do
	printf "%s;" "$f"
    mediainfo $f | sed -rn '/^General/,/^$/{s/Tagged date[[:space:]]*:.*([0-9]{4})-([0-9]{2})-([0-9]{2}).*/\1;\2/p}'
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
