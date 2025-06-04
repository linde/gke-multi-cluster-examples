

# Example cluster with a L4 load balancer using GKE service-managed NEGs.

This is an exploration that I did after I realized that MCS doesnt currently
work with L4. So, I wanted to learn what goes into managing a backend and
referncing GKE managed NEGs for a Service.

Currently, it just has one cluster, but i will soon put layer in clusters in
more than one region.

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


# now grab credentials to explore the workload and its service

CLUSTER_PROJ=$(echo var.gcp_project  | terraform console | tr -d '"')

CLUSTER_WEST_NAME=$(echo local.cluster_west.name  | terraform console | tr -d '"')
CLUSTER_WEST_LOC=$(echo local.cluster_west.location  | terraform console | tr -d '"')

CLUSTER_EAST_NAME=$(echo local.cluster_east.name  | terraform console | tr -d '"')
CLUSTER_EAST_LOC=$(echo local.cluster_east.location  | terraform console | tr -d '"')


gcloud container clusters get-credentials --project=${CLUSTER_PROJ} --location=${CLUSTER_WEST_LOC} ${CLUSTER_WEST_NAME}
kubectl config rename-context gke_${CLUSTER_PROJ}_${CLUSTER_WEST_LOC}_${CLUSTER_WEST_NAME} w

gcloud container clusters get-credentials --project=${CLUSTER_PROJ} --location=${CLUSTER_EAST_LOC} ${CLUSTER_EAST_NAME}
kubectl config rename-context gke_${CLUSTER_PROJ}_${CLUSTER_EAST_LOC}_${CLUSTER_EAST_NAME} e


kubectl --context=w get pod,service

```

## Verify the Redis works within the cluster

```bash
kubectl --context=w  port-forward services/redis-service 6379:6379 

# then from another terminal

echo PING | nc -q1 localhost 6379
```

This should reply `+PONG`.

## Step 2: Create the load balancer and dependancies

To do this, we need to supply an array of the k8s managed NEGs for the backend. We do this by querying the 
k8s Service and getting its annotation with NEG details and saving it as a input variable.

```bash

# update the list of zone suffices from above
cd ../tf-02-load-balancer/

# set the correct neg_zone_suffices into a terraform.tfvars file. 
# FYI this expects and dedicated project, it gathers *all* NEGS.
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

echo google_compute_address.internal_lb_ip.address | terraform console
echo local.redis_port | terraform console


# then start a container we can re-attach to across sessions, as helpful
kubectl --context w run --image=debian sleepy -- /bin/bash -c "sleep infinity"
# here is how we reattach
kubectl --context w exec sleepy -it -- bash

# and within the cluster via that bash prompt, use nc to do our L4 check of the VIP
apt update
apt install netcat-traditional

echo PING | nc -q1 [load balancer IP] [load balancer port]
[ctrl-D]
```

Profit!
