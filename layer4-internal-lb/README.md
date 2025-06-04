

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


cd tf-01-clusters-and-workload

# supply the value of the ${GCP_PROJECT} as a variable for terraform
# from within the terraform directory
cat <<EOF > terraform.tfvars
gcp_project = "${GCP_PROJECT}"
EOF

terraform init
terraform plan
terraform approve

# TODO: splain how to determine the zones with NEGs to plug into the loadbalancer.

cd ../tf-02-load-balancer
terraform init
terraform plan
terraform approve



```

## Explore

```bash
CLUSTER_PROJ=$(echo google_container_cluster.cluster.project  | terraform console | tr -d '"')
CLUSTER_NAME=$(echo google_container_cluster.cluster.name  | terraform console | tr -d '"')
CLUSTER_LOC=$(echo google_container_cluster.cluster.location  | terraform console | tr -d '"')

gcloud container clusters get-credentials --project=${CLUSTER_PROJ} --location=${CLUSTER_LOC} ${CLUSTER_NAME}

kubectl get ns
```

## Verify the Redis works within the cluster

```bash

kubectl  port-forward services/redis-service 6379:6379 

# then from another terminal

echo PING | nc -q1 localhost 6379
```

This should reply `+PONG`.



