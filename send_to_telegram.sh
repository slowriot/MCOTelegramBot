#!/bin/bash
# helper script to send the first argument to telegram

script="${BASH_SOURCE[0]}"
# walk through any symlinks
while [ -h "$script" ]; do
  script="$(readlink -f "$script")"
done
scriptdir="$(dirname "$script")"
cd "$scriptdir"

token=$(cat "$scriptdir/token.txt")

endpoint="https://api.telegram.org"
api="$endpoint/bot$token"

handlers_file="$scriptdir/handlers.txt"

disablepreview=false
if [ "$3" = "--nopreview" ]; then
  disablepreview=true
fi

############ Sending functions ############

function send_raw() {
  # 1 = raw command to send
  #echo "DEBUG: running: wget $api/$1"
  wget -q "$api/$1" -O - | jq .
  #echo "wget -q \"$api/$1\" -O - | jq ." >> sent_to_telegram.log
}
function send_message() {
  # 1 = chat id
  # 2 = text
  #text=$(url_encode "$2")
  text="$2"
  if $disablepreview; then
    send_raw "sendmessage?chat_id=$1&text=$text&disable_web_page_preview=true"
  else
    send_raw "sendmessage?chat_id=$1&text=$text"
  fi
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
function send_error() {
  # 1 = message
  # id: user or channel to send errors to, hardcoded for now
  send_message 118667124 "ERROR: $1"
}
function url_encode() {
  # 1 = string to encode
  perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$1"
}

send_message "$1" "$(url_encode "$2")"
