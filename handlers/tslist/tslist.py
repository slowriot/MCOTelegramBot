#!/usr/bin/env python
# Lists the players currently on teamspeak

TSLIST_LOCATION = "/home/minecraft/teamspeaklist.txt"
TSLIST_OUTPUT = "{count} players currently on TeamSpeak: {players}"

players = []

try:
	f = open(TSLIST_LOCATION, 'r')

	for line in f:
		players.append(line.strip())
finally:
	f.close()
	
if len(players) == 0:
	print("Nobody on TeamSpeak right now")
else:
	print TSLIST_OUTPUT.format(count = len(players), players = ", ".join(players))
