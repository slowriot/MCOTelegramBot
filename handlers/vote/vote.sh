#!/bin/bash
# voting script to accept pull requests etc

# get pending pull requests
jsondata=$(curl -s "https://api.github.com/repos/slowriot/MCOTelegramBot/pulls?state=open")

#args="${MCOBOT_TEXT#* }"
args="$(cut -sd ' ' -f 2- <<< "$MCOBOT_TEXT")"

if [ -z "$args" ]; then
  # list what to vote on
  num_pulls=$(jq ". | length" <<< "$jsondata")
  if [ -z "$num_pulls" ] || [ "$num_pulls" = "0" ]; then
    echo "There are no pull requests pending."
    echo "Check out the issues list for inspiration for something to write: https://github.com/slowriot/MCOTelegramBot/issues"
    exit
  elif [ "$num_pulls" = "1" ]; then
    echo "The following pull request is pending:"
  else
    echo "The following $num_pulls pull requests are pending:"
  fi
  for i in $(seq 0 $((num_pulls - 1))); do
    pull_id=$(jq -r ".[$i].number" <<< "$jsondata")
    pull_url=$(jq -r ".[$i].html_url" <<< "$jsondata")
    pull_user=$(jq -r ".[$i].user.login" <<< "$jsondata")
    pull_desc=$(jq -r ".[$i].title" <<< "$jsondata")
    echo "$pull_id: \"$pull_desc\" by $pull_user - $pull_url"
  done
  echo "Vote with /vote [number] [yes|no|veto]"
  exit
fi
  
# process votes
echo "Pull request accepting by voting to be implemented very soon"
echo "(DEBUG: args is \"$args\")"

# curl -s --request PUT "https://api.github.com/repos/slowriot/MCOTelegramBot/pulls/$pull_id/merge?client_id=xxxx&client_secret=yyyy"
