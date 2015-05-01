#!/bin/sh

function usage
{
    echo "create_grid photo_path"
}

function handle_dir
{
    path=$1
    dir=$2
    subpath=${dir#$path}
    if ! [ -n "$subpath" ]
    then
        return
    fi
    echo "handling $subpath"
    mkdir -p ./photos/$subpath
    file=$(echo $subpath | sed -e 's!/!-!').html
    sed -e "/href=\"$file\"/ s/<li>/<li class=\"active\">/" \
        grid.html.in.tmp > $file
    for i in $(find $dir -maxdepth 1 -iname "*.jpg"); do
        subpath=${i#$path}
        newpath=./photos/${subpath%$(basename $i)}$(basename $i .jpg)_250.jpg
        echo "convert $i -resize 250x250 $newpath"
        convert $i -resize 250x250 $newpath
        l1="        <li class=\"col-lg-3 col-md-4 col-xs-6 photo\">\n"
        l2="          <img src=\"$newpath\">\n"
        l3="          <br>\n"
        l4="          $subpath\n"
        l5="        </li>\n"
        li=$l1$l2$l3$l4$5
        sed -i -e "s!^.*@@PHOTOS@@*.\$!$li\n@@PHOTOS@@!" $file
    done
    sed -i -e "/@@PHOTOS@@/d" $file
}

if [ "$#" -lt 1 ]
then
    usage
    exit 0
fi


path=${1%/}/
cp grid.html.in grid.html.in.tmp
for d in $(find $path -type d)
do
    subpath=${d#$path}
    if ! [ -n "$subpath" ]
    then
        continue
    fi
    file=$(echo $subpath | sed -e 's!/!-!').html
    li="            <li><a href=\""$file"\">$subpath</a></li>"
    sed -i -e "s!^.*@@NAVBAR@@*.\$!$li\n@@NAVBAR@@!" grid.html.in.tmp
done
sed -i -e "/@@NAVBAR@@/d" grid.html.in.tmp
sed -e '/<ul class="row">/,+2 d' \
    -e '/href="index.html"/ s/<li>/<li class="active">/' \
    grid.html.in.tmp > index.html
for d in $(find $path -type d)
do
    handle_dir $path $d
done
rm grid.html.in.tmp
exit 0
