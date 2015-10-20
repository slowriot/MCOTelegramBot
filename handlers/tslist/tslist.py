#!/usr/bin/env python
# Lists the players currently on teamspeak

import urllib2

LIST_ENDPOINT = "URL GOES HERE"
LIST_OUTPUT = "{count} players currently on teamspeak: {players}"

players = urllib2.urlopen(LIST_ENDPOINT).read()

count = len(players.split(","))

print LIST_OUTPUT.format(count = count, players = players)
