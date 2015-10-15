#!/bin/bash
# Democratic crowdsourced general purpose support bot dedicated to the MCO
# community on Telegram
# Dispatcher which receives and processes webhooks from Telegram and dispatches
# them to the appropriate handler script (similar to exec).
# Initial Bash version (obviously).

scriptdir=$(dirname "${BASH_SOURCE[0]}")
token=$(cat "$scriptdir/token.txt")

endpoint="https://api.telegram.org"
api="$endpoint/bot$token"

handlers_file="$scriptdir/handlers.txt"

############ Sending functions ############

function send_raw() {
  # 1 = raw command to send
  #echo "DEBUG: running: wget $api/$1"
  wget -q "$api/$1" -O - | jq .
}
function send_message() {
  # 1 = chat id
  # 2 = text
  send_raw "sendmessage?chat_id=$1&text=$2"
}
function send_reply() {
  # 1 = chat id
  # 2 = message id
  # 3 = text
  send_raw "sendmessage?chat_id=$1&reply_to_message_id=$2&text=$3"
}
function send_busy() {
  # 1 = chat id
  send_raw "sendChatAction?chat_id=$1&action=typing"
}

########## Set and unset the webhook #########

if [ "$1" = "setup" ]; then
  echo "Requesting webhook setting for $thisurl"
  secreturl=$(cat "$scriptdir/secreturl.txt")
  thisurl="https://minecraftonline.com/cgi-bin/telegram_bot_webhook_$secreturl.sh"
  thisurl=$(./urlencode.sh <<< "$thisurl")
  send_raw "setWebhook?url=$thisurl"
  exit
fi
if [ "$1" = "unset" ]; then
  echo "Requesting webhook cancel"
  send_raw "setWebhook"
  exit
fi

############ Receive a message ############

if [ "$REQUEST_METHOD" = "POST" ]; then
  if [ "$CONTENT_LENGTH" = "" ]; then
    echo "ERROR: empty CONTENT_LENGTH when mode is POST" 1>&2
    exit 1
  fi
  if [ "$CONTENT_LENGTH" -gt 0 ]; then
    read -r -t 30 -N "$CONTENT_LENGTH" postdata <&0
  fi
else
  # this is GET data - redirect or hump and dump or whatever
  echo content-type: text/html
  echo
  echo "Sorry, nothing here"
  exit
fi

echo content-type: text/html
echo

############ Process the received data ############

# parse the json data into its constituent parts
jsondata=$(  jq -r '.'                      <<< "$postdata")
from_id=$(   jq -r ".message.from.id"       <<< "$jsondata")
username=$(  jq -r ".message.from.username" <<< "$jsondata")
chat_id=$(   jq -r ".message.chat.id"       <<< "$jsondata")
message_id=$(jq -r ".message.message_id"    <<< "$jsondata")
text=$(      jq -r ".message.text"          <<< "$jsondata")

# abort if we have invalid input
if [ "$from_id" = "" ] || [ "$chat_id" = "" ] || [ "$message" = "" ]; then
  # ignore any updates that don't have the components we need to reply
  echo "ERROR:$username:$chatid:$message"
  exit
fi

if [ "${message:0:1}" != "/" ]; then
  # this is not a command, so ignore it
  #send_message "$chat_id" "DEBUG: $username ($from_id) said: $message (not a command)"
  exit
fi

# the command is everything up to the first space
command="${message%% *}"
# sanitise the command to strip any silly business, and limit to 64 chars
command="$(tr -dc [:alnum:]'_-' <<< "$command" | head -c 64)"

handler=$(grep -v "^#" "$handlers_file" | grep "^$command" | head -1)

if [ -z "$handler" ]; then
  # no return, so this is not a command we recognise
  exit
fi

# trim away up to the first pipe delimiter to get the command to execute
handler=${handler#*|}

# export environment variables CGI style
env_prefix="MCOBOT_"
export "$prefix"FROM_ID="$from_id"
export "$prefix"FROM_USERNAME="$username"
export "$prefix"CHAT_ID="$chat_id"
export "$prefix"MESSAGE_ID="$message_id"
export "$prefix"TEXT="$text"

# yeah, this will run any code specified as a handler - security awareness is required
reply=$($handler)

# TODO: process different types of responses properly
send_message "$chat_id" "$reply"
