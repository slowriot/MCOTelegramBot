#!/usr/bin/env python
# Give a list of players online

import urllib2

LIST_ENDPOINT = "http://minecraftonline.com/cgi-bin/getplayerlist.sh"
LIST_OUTPUT = "{count} players online: {players}"

players = urllib2.urlopen(LIST_ENDPOINT).read()

count = len(players.split(","))

print LIST_OUTPUT.format(count=count, players=players)
