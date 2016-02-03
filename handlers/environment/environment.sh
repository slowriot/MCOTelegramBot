#!/bin/bash
# dump out environment state with regards to this chat

echo "Environment:"
env | grep "^MCOBOT_"
