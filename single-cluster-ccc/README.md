

# Example project with CCC and a workload using it

While not strictly a multi-cluster example, Custom Compute Class is very useful 
and comes up in platform conversations, so this example might be of interest.


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
cat <<EOF > terraform.tfvars
gcp_project = "${GCP_PROJECT}"
EOF

```

## Explore

```bash
CLUSTER_PROJ=$(echo google_container_cluster.primary_cluster.project  | terraform console | tr -d '"')
CLUSTER_NAME=$(echo google_container_cluster.primary_cluster.name  | terraform console | tr -d '"')
CLUSTER_LOC=$(echo google_container_cluster.primary_cluster.location  | terraform console | tr -d '"')

gcloud container clusters get-credentials --project=${CLUSTER_PROJ} --location=${CLUSTER_LOC} ${CLUSTER_NAME}


# see the pods spread to different nodes
kubectl get pods -o json | jq '.items[].spec.nodeName' | uniq -c | sort -rn

```
