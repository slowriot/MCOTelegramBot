#!/bin/bash
# wrapper for url encoding stuff either from commandline or stdin

string="$1"
if [ -z "$string" ]; then
  string=$(cat)
fi

if [ -z "$string" ]; then
  exit
fi

perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$string"
