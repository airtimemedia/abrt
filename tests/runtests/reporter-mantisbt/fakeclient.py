#!/usr/bin/env python

import requests

url = 'http://localhost:12345'

r = requests.post(url=url, data='post data')
print r.headers
print r.text
