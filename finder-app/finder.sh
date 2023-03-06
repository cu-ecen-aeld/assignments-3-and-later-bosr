#!/bin/sh

if [ $# -ne 2 ]; then
  echo expected 2 arguments
  return 1
fi

filesdir=$1
searchstr=$2

if [ ! -d "$filesdir" ]; then
  echo "$filesdir" is not a directory
  return 1
fi

res=$(grep -r -c $searchstr $filesdir)
X=$(echo "$res" | wc -l)
Y=$(echo "$res" | cut -f2 -d: | awk '{s+=$1} END {print s}')

echo "The number of files are $X and the number of matching lines are $Y"
