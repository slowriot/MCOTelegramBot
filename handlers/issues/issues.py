#!/usr/bin/env python
import json
import urllib2

URL = "https://api.github.com/repos/slowriot/MCOTelegramBot/issues"

res = json.load(urllib2.urlopen(URL))

for issue in res:
    if 'pull_request' in issue:
        continue

    print("{number}: \"{title}\" by {user[login]} - {html_url}".format(**issue))

