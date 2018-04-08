#!/bin/bash


if [ -z "$1" ];  then
    git ls-tree --full-tree --name-only -r `git rev-list -n 1 master`
else
    git ls-tree --full-tree --name-only -r `git rev-list -n 1 --before="$1" master`
fi
