import urllib.request
import urllib.error
import json

url = 'http://localhost:8000/api/ingest/install/'
data = json.dumps({'device_id': 'sync-test-dev', 'kind': 'first_install', 'country': 'US'}).encode()
headers = {'Authorization': 'ApiKey nx_sk_xllrgn0nc2b', 'Content-Type': 'application/json'}

req = urllib.request.Request(url, data=data, headers=headers)
try:
    urllib.request.urlopen(req)
except urllib.error.HTTPError as e:
    with open('error.html', 'w', encoding='utf-8') as f:
        f.write(e.read().decode())
    print("Saved error to error.html")
