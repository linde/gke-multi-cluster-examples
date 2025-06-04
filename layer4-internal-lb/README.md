

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

# supply the value of the ${GCP_PROJECT} as a variable for terraform
# from within the terraform directory
cat <<EOF > tf-01-clusters-and-workload/terraform.tfvars
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

CLUSTER_PROJ=$(echo google_container_cluster.cluster.project  | terraform console | tr -d '"')
CLUSTER_NAME=$(echo google_container_cluster.cluster.name  | terraform console | tr -d '"')
CLUSTER_LOC=$(echo google_container_cluster.cluster.location  | terraform console | tr -d '"')

gcloud container clusters get-credentials --project=${CLUSTER_PROJ} --location=${CLUSTER_LOC} ${CLUSTER_NAME}

kubectl get pod,service


```

## Verify the Redis works within the cluster

```bash
kubectl  port-forward services/redis-service 6379:6379 

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

# set the correct neg_zone_suffices into a terraform.tfvars file
NEG_ZONES=$(kubectl get service redis-service -ojson | jq -r '.metadata.annotations["cloud.google.com/neg-status"]' |  jq -c  .zones)
cat <<EOF > terraform.tfvars
neg_zone_suffices = ${NEG_ZONES}
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


# then start a container we can re-attach to
kubectl run --image=debian sleepy -- /bin/bash -c "sleep infinity"

kubectl exec sleepy -it -- bash
# and within that bash prompt in the cluster so we can hit internal VIPs
apt update
apt install netcat-traditional

echo PING | nc -q1 [load balancer IP] [load balancer port]
[ctrl-D]
```

