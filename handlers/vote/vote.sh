#!/bin/bash
# voting script to accept pull requests etc

# settings: how many yes votes minus no votes are required to accept
quorum=15

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
# take the first argument, issue number, restrict to digits only
pull_id="$(tr -dc [:digit:] <<< "${args%% *}")"
if [ -z "$pull_id" ]; then
  echo "Please vote by issue number."
  exit
fi
# validate that this is an open pull request
jsondata=$(curl -s "https://api.github.com/repos/slowriot/MCOTelegramBot/pulls/$pull_id")
pull_mergeable=$(jq -r ".mergeable" <<< "$jsondata")
if [ "$pull_mergeable" != "true" ]; then
  echo "There is no mergeable pull request numbered $pull_id."
  exit
fi
# take the second argument
arg2="${args#* }"
# lowercase
arg2="${arg2,,}"
if [ "${arg2}" = "yes" ]; then
  echo "This is not yet implemented, but your hair looks lovely."
  # check quorum
  # merge
  # curl -s --request PUT "https://api.github.com/repos/slowriot/MCOTelegramBot/pulls/$pull_id/merge?client_id=xxxx&client_secret=yyyy"
elif [ "${arg2}" = "no" ]; then
  echo "This is not yet implemented, but have you lost weight?"
elif [ "${arg2}" = "veto" ]; then
  echo "This is not yet implemented, and let's face it, if it were you probably wouldn't have perms to use it anyway."
elif [ "${arg2}" = "maybe" ]; then
  echo "Non-vote accepted on pull request $pull_id."
else
  echo "Possible voting options are \"yes\", \"no\", and admins may use \"veto\"."
fi
