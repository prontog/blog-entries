

Moving your photos using *ImageMagik*:
```bash
for f in $(find -type f -name '*.jpg'); do
	printf "%s " $f
	identify -verbose $f | sed -nr 's/.*DateTimeOriginal: ([0-9]{4}):([0-9]{2}):([0-9]{2}).*/\1 \2/p'
	echo ""
done | sed -u '/^$/d' | while read f y m; do
	if ! [[ -f $f ]]; then
        echo "Not a file $f" >&2
        continue
    fi
    if [[ -z $y ]]; then
        echo "Year is empty. Skipping $f" >&2
        continue
    fi
    if [[ -z $m ]]; then
        echo "Month is empty. Skipping $f" >&2
        continue
    fi
	mkdir -p ~/Nextcloud/Photos/mobile/$y/$m
	mv $f ~/Nextcloud/Photos/mobile/$y/$m
done
```

Moving your videos using *mediainfo*:
```bash
for f in $(find -type f -name '*.mp4'); do
    printf "%s " $f
    mediainfo $f | sed -rn '/^General/,/^$/{s/Tagged date[[:space:]]*:.*([0-9]{4})-([0-9]{2})-([0-9]{2}).*/\1  \2/p}'
    echo ""
done | sed -u '/^$/d' | while read f y m; do
    if ! [[ -f $f ]]; then
        echo "Not a file $f" >&2
        continue
    fi
    if [[ -z $y ]]; then
        echo "Year is empty. Skipping $f" >&2
        continue
    fi
    if [[ -z $m ]]; then
        echo "Month is empty. Skipping $f" >&2
        continue
    fi
    mkdir -p /cygdrive/e/pronto/Nextcloud/Videos/mobile/$y/$m
    mv $f /cygdrive/e/pronto/Nextcloud/Videos/mobile/$y/$m
done
```
