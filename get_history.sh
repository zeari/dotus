#!/bin/bash

#FILE=pods/prometheus-0
FILE=$1
for SHA in $(git log  --oneline --no-abbrev-commit -- $FILE | cut -d' ' -f1); do
  echo $(git show $SHA:time)
  echo $(git show $SHA:$FILE)
done

