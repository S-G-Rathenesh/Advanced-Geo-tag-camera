import urllib.request, urllib.error, json
req = urllib.request.Request(
    'https://advanced-geo-tag-camera.onrender.com/api/v1/auth/demo', 
    data=b'{"username": "demo_officer"}', 
    headers={'Content-Type': 'application/json'}
)
try:
    res = urllib.request.urlopen(req)
    print(res.read().decode())
except urllib.error.HTTPError as e:
    print("ERROR:", e.code)
    print(e.read().decode())
