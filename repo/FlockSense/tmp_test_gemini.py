import json
import urllib.request
import urllib.error

key = 'REPLACE_WITH_YOUR_GEMINI_API_KEY'
body = {
    'contents': [
        {
            'parts': [
                {'text': 'Reply only with valid JSON: {"healthScore":80,"healthStatus":"Good"}'}
            ]
        }
    ]
}
req = urllib.request.Request(
    f'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={key}',
    data=json.dumps(body).encode(),
    headers={'Content-Type': 'application/json'},
    method='POST',
)
try:
    with urllib.request.urlopen(req, timeout=30) as res:
        print('STATUS', res.status)
        print(res.read().decode())
except urllib.error.HTTPError as e:
    print('HTTP', e.code)
    print(e.read().decode())
except Exception as e:
    print(type(e).__name__, e)
