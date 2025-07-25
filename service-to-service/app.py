
import os
import requests
import json

from flask import Flask, request

app = Flask(__name__)

@app.route('/delegate')
def delegate():
    HTTPBIN_ENDPOINT = os.getenv('HTTPBIN_ENDPOINT', 'http://httpbin.default.svc.cluster.local:8080/headers')

    outgoing_headers = {
        "Authorization" : request.headers.get("Authorization", default="[unset]")
    }
    response = requests.get(HTTPBIN_ENDPOINT, headers=outgoing_headers, timeout=5)

    returnObj = {"endpoint": HTTPBIN_ENDPOINT}
    if response.ok: 
        httpbin_data = response.json()
        returnObj["response"] = httpbin_data
    else:
        returnObj["status_code"] = response.status_code
        returnObj["reason"] = response.reason

    return json.dumps(returnObj)


@app.route('/')
def ok():
    return f'OK'
