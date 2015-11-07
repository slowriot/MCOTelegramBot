#!/usr/bin/env python
# Lists the players currently on teamspeak
# final loc: /home/minecraft/teamspeaklist.txt

TSLIST_LOCATION = "test.txt"
TSLIST_OUTPUT = "{count} players currently on TeamSpeak: {players}"

file = open(TSLIST_LOCATION, 'r')

count = 0
players = ""

for line in file:
	if line == '\n':
		continue
	count += 1
	players += (line.strip() + ", ")

if count == 0:
	print("Nobody on TeamSpeak right now")
else:
	print TSLIST_OUTPUT.format(count = count, players = players[:-2])
