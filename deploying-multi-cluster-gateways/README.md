

# Deploying Multi-cluster Gateways (in terraform)

This little project just works out the terraform necessary for the example [deploying-multi-cluster-gateways](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-multi-cluster-gateways).

```bash

# set up a new, empty project. 

export GCP_PROJECT=[PROJECT]
export GCP_FOLDER=[FOLDER]
export GCP_BILLING_ACCCOUNT=[BILLING ACCOUNT GUID]


gcloud projects create ${GCP_PROJECT} --folder=${GCP_FOLDER}
gcloud billing projects link $GCP_PROJECT --billing-account ${GCP_BILLING_ACCCOUNT}


# supply the value of the ${GCP_PROJECT} as a variable for terraform
cat <<EOF > terraform.tfvars
gcp_project="${GCP_PROJECT}"
EOF

terraform init
terraform plan
terraform apply 

# get some coffee, and know a re-apply might be required because resource 
# ordering and dependancies. we've tried to account for this, but if 
# terraform errors out, it's worth just re-applying. if that's the case, 
# please consider filing an issue and/or pinging linde@.

```

# Verification

After a little while you can verify things:

```bash

# get creds for the hub cluster

HUB_PROJ=$(echo google_container_cluster.hub.project  | terraform console | tr -d '"')
HUB_NAME=$(echo google_container_cluster.hub.name  | terraform console | tr -d '"')
HUB_LOC=$(echo google_container_cluster.hub.location  | terraform console | tr -d '"')
gcloud container clusters get-credentials --project=${HUB_PROJ} --location=${HUB_LOC} ${HUB_NAME}

kubectl get gateway -n store

export VIP=$(kubectl get gateway -n store external-http -ojson | jq .status.addresses[0].value -r); echo ${VIP}
curl -s -H "host: store.example.com" http://${VIP} | jq .
curl -s -H "host: store.example.com" http://${VIP}/worker{0,1} | jq . 

# if for any reason you want to get access to a worker, do the following replacing 0 with 1 as helpful

WORKER_NAME=$(echo local.mcg_0.name  | terraform console | tr -d '"')
WORKER_LOC=$(echo var.worker_locations[0]  | terraform console | tr -d '"')
gcloud container clusters get-credentials --project=${HUB_PROJ} --location=${WORKER_LOC} ${WORKER_NAME}

```

# TODO ordering issues

> Error: unable to build kubernetes objects from release manifest: [resource mapping not found for name: "store" namespace: "store" from "": no matches for kind "ServiceExport" in version "net.gke.io/v1"
