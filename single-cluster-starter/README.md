

# setup

```bash

# set up a new, empty project. 

export GCP_PROJECT=[PROJECT]
export GCP_FOLDER=[FOLDER]
export GCP_BILLING_ACCCOUNT=[BILLING ACCOUNT GUID]


gcloud projects create ${GCP_PROJECT} --folder=${GCP_FOLDER}
gcloud billing projects link $GCP_PROJECT --billing-account ${GCP_BILLING_ACCOUNT}


# supply the value of the ${GCP_PROJECT} as a variable for terraform

cd tf
cat <<EOF > terraform.tfvars
gcp_project="${GCP_PROJECT}"
EOF

```

# verify

```bash
WORKER_PROJ=$(echo google_container_cluster.worker.project  | terraform console | tr -d '"')
WORKER_NAME=$(echo google_container_cluster.worker.name  | terraform console | tr -d '"')
WORKER_LOC=$(echo google_container_cluster.worker.location  | terraform console | tr -d '"')

gcloud container clusters get-credentials --project=${WORKER_PROJ} --location=${WORKER_LOC} ${WORKER_NAME}

kubectl get configmap marker


```