

## Context 

This is an exploration to familiarize myself with istio authn and service-to-service calls.
Very quick, very dirty, and largely vibe coded.


## Running things locally first


```bash

# activate a venv, then
source .venv/bin/activate
pip install flask requests

# run httpbin 
export HTTPBIN_PORT=8888
docker run --name httpbin -d --rm -it -p ${HTTPBIN_PORT}:80 kennethreitz/httpbin

# try it directly
export HTTPBIN_ENDPOINT=http://localhost:${HTTPBIN_PORT}/headers
curl -s ${HTTPBIN_ENDPOINT}

# ok, now let's try a service that calls our httpbin service
# it serves from FLASK_PORT and uses HTTPBIN_ENDPOINT, if in the env
export FLASK_PORT=8080
flask run --host=0.0.0.0 --port=${FLASK_PORT} 

# in another terminal, re export FLASK_PORT then
curl -s http://localhost:${FLASK_PORT}/delegate | jq .


## clean up by ctl-c the flask app and docker kill httpbin
docker kill httpbin

```

## Getting Set up with k8s

```bash

kind create cluster --name token-fun

# deploy isitio, use docker image to forgo installing istioctl CLI
kubectl create namespace istio-system
docker run --rm -it istio/istioctl:1.26.2 manifest generate | kubectl apply -f -
# turn on istio for the default namespace where our stuff will be
kubectl label namespace default istio-injection=enabled


## ok, now deploy our "app" via a configmap (too lazy to make a container)
kubectl create configmap webapp-configmap --from-file=app.py=app.py

## then the services
kubectl apply -f ./k8s-config

```

## trying things out using the gateway

```bash

# first get the gatway IP
export GW_IP=$(kubectl get service -n istio-system istio-ingressgateway -ojson | jq -r .status.loadBalancer.ingress[0].ip)
echo ${GW_IP}

# first try httpbin directly; it matches via a virtualhost httpbin.example.com
curl -si -H "Host: httpbin.example.com" http://${GW_IP}/headers


# now the wrapping service, it serves on / on any other host

# first just check for `OK`
curl -si http://${GW_IP}/

# and the service calling the other service 
curl -s  http://${GW_IP}/delegate | jq .

```

In particular, you can see envoy headers on the embedded request details, 
e.g. `X-Forwarded-Client-Cert`.

## getting authn into the picture

Warning -- the previous example `curl` commands wont work anymore.

```bash
kubectl apply -f k8s-config-authn/

```

The policy above requires a valid JWT from the istio testing issuer and requests requests with missing or invalid JWTs:

```bash
# following should 401
curl -is -H "Authorization: Bearer invalid"  http://${GW_IP}/

# this one should 403
curl -is  http://${GW_IP}/

```

To see it allow a valid JWT from the right issuer, try:

```bash
TOKEN=$(curl -s https://raw.githubusercontent.com/istio/istio/release-1.26/security/tools/jwt/samples/demo.jwt)

curl -is -H "Authorization: Bearer $TOKEN"  http://${GW_IP}/

```
This returns a '200 OK`. Importantly, the app also relays the authn token, something
you can see in the respose headers the nested call provides.

```bash
curl -s  -H "Authorization: Bearer $TOKEN"  http://${GW_IP}/delegate  | jq .response.headers.Authorization
```
