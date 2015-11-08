#!/bin/bash
# script to make sure we're all synced up to the git repo

scriptdir="$(dirname "${BASH_SOURCE[0]}")"

echo "Pulling from the repository..."
git pull
#chown www-data:www-data "$scriptdir" -R
