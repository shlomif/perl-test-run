#!/bin/bash

svn_base_url="https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG"
trunk_url="$svn_base_url/trunk"
tags_url="$svn_base_url/tags/releases"

trunk_dir="$HOME/progs/perl/cpan/Test/Test-Harness/trunk"
modules_dir="$trunk_dir/modules"

tag_and_release()
{
    local base dir tags_dir two_digit_nest arc this_tag
    base="$1"
    shift
    dir="$1"
    shift
    tags_dir="$1"
    shift
    two_digit_nest="$1"
    shift

    echo "$modules_dir/$dir"
    cd "$modules_dir/$dir"
    rm -f *.tar.gz
    perl Build.PL
    ./Build dist
    arc="$(ls *.tar.gz)"
    echo "ARC == $arc"

    ver="$(echo "$arc" | perl -lpe 'm{-([\d\.]+)\.tar\.gz\z}; $_=$1;')"
    echo "VER == $ver"

    if [ "$tags_dir" == "" ] ; then
        this_tag="$tags_url"
    else
        this_tag="$tags_url/$tags_dir"
    fi

    if $two_digit_nest ; then
        two_digit_ver="$(echo "$ver" | perl -lpe 'm{(\d.\d\d)}; $_=$1')"
        echo "TWO DIG VER == $two_digit_ver"
        this_tag="$this_tag/$two_digit_ver"
        svn mkdir -q -m "Creating directory for the $base $two_digit_ver releases" "$this_tag"
        this_tag="$this_tag/$ver"
    else
        this_tag="$this_tag/$ver"
    fi

    # Do the actual tagging
    svn copy -m "Tagging $base as release $ver" "$trunk_url" "$this_tag"

    cpan-upload-http "$arc"
}

# tag_and_release "Test-Run" "Test-Shlomif-Harness" "" true
tag_and_release "Test-Run-CmdLine" "Test-Run-CmdLine" "modules/Test-Run-CmdLine" true
