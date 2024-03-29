#!/bin/sh
# ==============================================================================
# name:         create_grid.sh
# description:  Creates a bootstrap powered HTML website displaying thumbnails
#               of every photo in given directory.
# author:       Lennart Braun <lenerd@posteo.de>
# license:      MIT
# date:         20150501
# version:      0.1
# requirements: imagemagick, sed
# usage:        sh create_grid.sh photo_path destination
# ==============================================================================

function usage
{
    echo "create_grid photo_path destination_path"
}

function handle_dir
{
    path="$1"
    dest="$2"
    dir="$3"
    subpath=${dir#$path}
    if ! [ -n "$subpath" ]
    then
        return
    fi
    echo "handling $subpath"
    mkdir -p "$dest/photos/$subpath"
    file=$(echo $subpath | sed -e 's!/!-!').html
    sed -e "/href=\"$file\"/ s/<li>/<li class=\"active\">/" \
        "$dest/grid.html.in.tmp" > "$dest/$file"
    find "$dir" -type f -maxdepth 1 -iname "*.jpg" -print0 | \
    while IFS= read -r -d $'\0' i
    do
        subpath=${i#$path}
        base_i=$(basename "$i")
        newpath="photos/${subpath%$(basename "$i")}${base_i%.*}_250.jpg"
        if [ -f "$dest/$newpath" ]
        then
            echo "file exists: $dest/$newpath"
        else
            echo "convert $i -resize 250x250 $dest/$newpath"
            convert "$i" -resize 250x250 "$dest/$newpath"
        fi
        l1="        <li class=\"col-lg-3 col-md-4 col-xs-6 photo\">\n"
        l2="          <img src=\"$newpath\">\n"
        l3="          <br>\n"
        l4="          $subpath\n"
        l5="        </li>\n"
        li="$l1$l2$l3$l4$l5"
        sed -i -e "s!^.*@@PHOTOS@@*.\$!$li\n@@PHOTOS@@!" "$dest/$file"
    done
    sed -i -e "/@@PHOTOS@@/d" "$dest/$file"
}

if [ "$#" -lt 2 ]
then
    usage
    exit 1
fi

if ! [ -d "bootstrap-dist" ]
then
    echo "you need to extract bootstrap to ./bootstrap-dist"
    exit 1
fi

set -e

path=${1%/}/
dest=${2%/}
mkdir -p "$dest"
cp grid.html.in $dest/grid.html.in.tmp
cp -r css bootstrap-dist "$dest/"
find "$path" -type d -print0 | while IFS= read -r -d $'\0' d
do
    subpath=${d#$path}
    if ! [ -n "$subpath" ]
    then
        continue
    fi
    file="$(echo $subpath | sed -e 's!/!-!').html"
    li="            <li><a href=\""$file"\">$subpath</a></li>"
    sed -i -e "s!^.*@@NAVBAR@@*.\$!$li\n@@NAVBAR@@!" "$dest/grid.html.in.tmp"
done
sed -i -e "/@@NAVBAR@@/d" "$dest/grid.html.in.tmp"
sed -e '/<ul class="row">/,+2 d' \
    -e '/<div class="content container">/ a \      <p class="lead">Use the navigation above to browse the photo collection.</p>' \
    "$dest/grid.html.in.tmp" > "$dest/index.html"
find "$path" -type d -print0 | while IFS= read -r -d $'\0' d
do
    handle_dir "$path" "$dest" "$d"
done
rm "$dest/grid.html.in.tmp"
exit 0
