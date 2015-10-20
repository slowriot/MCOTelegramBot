#!/bin/bash
# voting script to accept pull requests etc

# settings: how many yes votes minus no votes are required to accept
quorum=10

scriptdir="$(dirname "${BASH_SOURCE[0]}")"

# get pending pull requests
client_id="$(cat "$scriptdir/client_id.txt")"
client_secret="$(cat "$scriptdir/client_secret.txt")"
jsondata=$(curl -s --max-time 5 "https://api.github.com/repos/slowriot/MCOTelegramBot/pulls?state=open&client_id=$client_id&client_secret=$client_secret")

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
jsondata=$(curl -s --max-time 5 "https://api.github.com/repos/slowriot/MCOTelegramBot/pulls/$pull_id?client_id=$client_id&client_secret=$client_secret")
pull_mergeable=$(jq -r ".mergeable" <<< "$jsondata")
if [ "$pull_mergeable" != "true" ]; then
  echo "There is no mergeable pull request numbered $pull_id."
  echo "DEBUG: full response was: "
  echo "$jsondata"
  exit
fi
# take the second argument
arg2="${args#* }"
# lowercase
arg2="${arg2,,}"
votes_no_file="$scriptdir/votes-$pull_id-yes.txt"
votes_yes_file="$scriptdir/votes-$pull_id-no.txt"
if [ "${arg2}" = "yes" ]; then
  # apply this user's vote to the yes votes and remove it from the no votes if it was there previously
  echo "$MCOBOT_FROM_ID" >> "$votes_yes_file"
  temp="$(sort "$votes_yes_file" 2>/dev/null | uniq)"
  echo "$temp" > "$votes_yes_file"
  temp="$(grep -v "^$MCOBOT_FROM_ID$" "$votes_no_file" 2>/dev/null)"
  echo "$temp" > "$votes_no_file"
  # check quorum
  votes_yes=$(wc -w < "$votes_yes_file")
  votes_no=$( wc -w < "$votes_no_file")
  votes_total=$((votes_yes - votes_no))
  if [ "$votes_total" -ge "$quorum" ]; then
    # merge
    commit_message="$("$scriptdir"/../../urlencode.sh "Automatically merged after Telegram vote ($votes_yes in favour, $votes_no against)")"
    repo_secret="$(cat "$scriptdir/repo_secret.txt")"
    response="$(
      curl -s \
        -u slowriot:"$repo_secret" \
        -H "Content-Type: application/json" \
        --request PUT \
        -d "{\"commit_message\":\"$commit_message\"}" \
        "https://api.github.com/repos/slowriot/MCOTelegramBot/pulls/$pull_id/merge?client_id=$client_id&client_secret=$client_secret" \
        | jq -r .message
    )"
    echo "Voting for request $pull_id: $response"
    git pull
  else
    echo "Votes for pull request $pull_id - in favour: $votes_yes, against: $votes_no.  $((quorum - votes_total)) more votes required to accept."
  fi
elif [ "${arg2}" = "no" ]; then
  # apply this user's vote to the no votes and remove it from the yes votes if it was there previously
  echo "$MCOBOT_FROM_ID" >> "$votes_no_file"
  temp="$(sort "$votes_no_file" 2>/dev/null | uniq)"
  echo "$temp" > "$votes_no_file"
  temp="$(grep -v "^$MCOBOT_FROM_ID$" "$votes_yes_file" 2>/dev/null)"
  echo "$temp" > "$votes_yes_file"
  # check quorum
  votes_yes=$(wc -w < "$votes_yes_file")
  votes_no=$( wc -w < "$votes_no_file")
  votes_total=$((votes_yes - votes_no))
  if [ "$votes_total" -le "-$quorum" ]; then
    # close
    echo "This would normally close the request but that is not yet implemented, however that's a nice tan."
    git pull
  else
    echo "Votes for pull request $pull_id - in favour: $votes_yes, against: $votes_no.  $((quorum - votes_total)) more votes required to accept."
  fi
elif [ "${arg2}" = "veto" ]; then
  echo "This is not yet implemented, and let's face it, if it were you probably wouldn't have perms to use it anyway."
elif [ "${arg2}" = "maybe" ]; then
  echo "Non-vote accepted on pull request $pull_id."
else
  echo "Possible voting options are \"yes\", \"no\", and admins may use \"veto\"."
fi
