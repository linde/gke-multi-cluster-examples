

# Exploring Flux with fleet (in terraform)

```bash

# set up a new, empty project. 

export GCP_PROJECT=[PROJECT]
export GCP_FOLDER=[FOLDER]
export GCP_BILLING_ACCCOUNT=[BILLING ACCOUNT GUID]


gcloud projects create ${GCP_PROJECT} --folder=${GCP_FOLDER}
gcloud billing projects link $GCP_PROJECT --billing-account ${GCP_BILLING_ACCCOUNT}


# supply the value of the ${GCP_PROJECT} as a variable for terraform
echo gcp_project=\"${GCP_PROJECT}\" > terraform.tfvars

terraform init
terraform plan
terraform apply 

# get some coffee

```

# Interacting with the clusters


```bash
# get creds for the first worker cluster

WORKER1_FLEET=$(echo google_container_cluster.worker_clusters[var.worker_locations[0]].fleet[0].project | terraform console | tr -d '"')
WORKER1_LOC=$(echo google_container_cluster.worker_clusters[var.worker_locations[0]].fleet[0].membership_location | terraform console | tr -d '"')
WORKER1_MEMBER=$(echo google_container_cluster.worker_clusters[var.worker_locations[0]].fleet[0].membership_id | terraform console | tr -d '"')

gcloud container fleet memberships get-credentials --project=${WORKER1_FLEET} --location=${WORKER1_LOC} ${WORKER1_MEMBER}

```