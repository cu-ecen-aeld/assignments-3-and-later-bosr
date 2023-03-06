#!/bin/sh

if [ $# -ne 2 ]; then
  echo expected 2 arguments
  return 1
fi

writefile=$1
writestr=$2

writedir=$(dirname "$writefile")
mkdir -p "$writedir"

echo "$writestr" > "$writefile"
