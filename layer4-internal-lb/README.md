
# Example cluster with a L4 load balancer using GKE service-managed NEGs.

Ultimately, this project is just a terraform port of the GKE doc, [feedbackContainer-
native load balancing through standalone zonal NEGs](https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg).
It came about when I was surprised to learn that GKE Multi-cluster
Gateway/Service doesn't currently work with L4 services; it assumes L7 http application
load balancing.  Because I was surprised by that, I wanted to learn what goes  into managing 
a backend and referncing GKE managed NEGs for a Service.

The setup has two clusters in respective regions and runs a workload fronted by
a Kubernetes Service. This service has annotations which cause GCP to manage 
[Network Endpoint Groups (or NEGs)](https://cloud.google.com/load-balancing/docs/negs)
bound to the service's pods in each region where the workload ends up deployed.

The "interesting" part here is scraping those NEGs and using them in a backend for
a cross regional load balancer. In this case, I create an internal one but you can
definitely use this for a cross region, multi-cluster L4 load balancer (with the caveat
that you need to collect the NEGs and reapply any time you app changes or scales.

## Setup

```bash

# set up a new, empty project. 

export GCP_PROJECT=[PROJECT]
export GCP_FOLDER=[FOLDER]
export GCP_BILLING_ACCCOUNT=[BILLING ACCOUNT GUID]

gcloud projects create ${GCP_PROJECT} --folder=${GCP_FOLDER}
gcloud billing projects link $GCP_PROJECT --billing-account ${GCP_BILLING_ACCOUNT}

# supply the value of the ${GCP_PROJECT} as a variable for terraform for the first tf dir
cd tf-01-clusters-and-workload
cat <<EOF > terraform.tfvars
gcp_project = "${GCP_PROJECT}"
EOF

```

## Part 1: Set up the clusters and their workload 

This first part sets up the clusters and their workload (in this case, Redis). The workload has a service that has NEG 
names manually applied so we can grab them and use them in the next setion where we set up a loadbalancer and all its dependancies.


```bash

# within tf-01-clusters-and-workload

terraform init
terraform plan
terraform approve

# get coffee ... time passes ...

# once the terraform applies and the deployments are running, grab credentials to explore the
# workload and its service. we use the cluster in the west region but either works

CLUSTER_PROJ=$(echo var.gcp_project  | terraform console | tr -d '"')
CLUSTER_NAME=$(echo local.cluster_west.name  | terraform console | tr -d '"')
CLUSTER_LOC=$(echo local.cluster_west.location  | terraform console | tr -d '"')

gcloud container clusters get-credentials --project=${CLUSTER_PROJ} --location=${CLUSTER_LOC} ${CLUSTER_NAME}

kubectl get pod,service

```

## Verify the Redis works within the cluster

```bash
kubectl port-forward services/redis-service 6379:6379 

# then from another terminal

echo PING | nc -q1 localhost 6379
```
This should reply `+PONG`.

## Step 2: Create the load balancer and dependancies

To create the load balancer, we start by getting the set of k8s managed NEGs for the backend. We get these 
via `gcloud`, then reformat their resource self-links to match what's expected for the backend terraform resource

```bash
cd ../tf-02-load-balancer/

# set the combined_neg_zones into a terraform.tfvars file. 
# FYI this collects *all* NEGs for a project, additional care might be needed if you're using this in a project with other services
COMBINED_NEG_ZONES=$(
    gcloud compute network-endpoint-groups list  --project ${CLUSTER_PROJ}  --format=json | jq '.[].selfLink | sub("^.*/v1/"; "")' | jq . -sc
)

cat <<EOF > terraform.tfvars
combined_neg_zones = ${COMBINED_NEG_ZONES}
EOF

terraform init
terraform plan
terraform apply

```

## Verify using the load balancer endpoint

```bash

# first, grab the IP and port address of the load balancer

echo google_compute_address.internal_lb_ip_xreg.address | terraform console
echo local.redis_port | terraform console

# since this was internal, lets just use a shell within one of the clusters to verify connectivity
kubectl run -it --image=debian bash -- /bin/bash 

# within the cluster, install and use netcat (ie nc) to do our L4 check of the VIP
apt update
apt install netcat-traditional

echo PING | nc -q1 [load balancer IP] [load balancer port]
# it should reply: +PONG
[ctrl-D]
```

Profit!
