#!/bin/bash

scriptdir="$(dirname "${BASH_SOURCE[0]}")"

args="$(cut -sd ' ' -f 2- <<< "$MCOBOT_TEXT")"

if [ -z "$args" ]; then
  echo "What do you want to search? Try again with /lmgtfy <query>"
else
  escaped_args="$("$scriptdir"/../../urlencode.sh "$args")"
  echo "http://lmgtfy.com/?q=$escaped_args"
fi
