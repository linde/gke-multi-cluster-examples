

# Deploying Inference Gateway (in terraform)


```bash

# set up a new, empty project. 

export GCP_PROJECT=[PROJECT]
export GCP_FOLDER=[FOLDER]
export GCP_BILLING_ACCCOUNT=[BILLING ACCOUNT GUID]


gcloud projects create ${GCP_PROJECT} --folder=${GCP_FOLDER}
gcloud billing projects link $GCP_PROJECT --billing-account ${GCP_BILLING_ACCCOUNT}


# supply the value of the ${GCP_PROJECT} as a variable for terraform

cd tf
cat <<EOF > terraform.tfvars
gcp_project="${GCP_PROJECT}"
EOF

terraform init
terraform plan
terraform apply 


```
# Model Access

FYI -- they are not kidding around with this tutorial step: [Get access to the model](https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-with-gke-inference-gateway#model-access). I glossed over this and took a while to find the helpful error messages to this effect 
when things weren't coming up cleanly.  Meta's acceptance of your application might take a while, so plan accordingly.


# Verification


```bash

WORKER_PROJ=$(echo google_container_cluster.worker.project  | terraform console | tr -d '"')
WORKER_NAME=$(echo google_container_cluster.worker.name  | terraform console | tr -d '"')
WORKER_LOC=$(echo google_container_cluster.worker.location  | terraform console | tr -d '"')
gcloud container clusters get-credentials --project=${WORKER_PROJ} --location=${WORKER_LOC} ${WORKER_NAME}


# wait quite a little while for things to get ready
kubectl wait --for=condition=Ready deployment/vllm-llama3-8b-instruct --timeout=10m

kubectl port-forward services/vllm-server 8000 &


curl -X POST "http://localhost:8000/v1/completions" \
	-H "Content-Type: application/json" \
	--data '{
		"model": "meta-llama/Llama-3.2-1B-Instruct",
		"prompt": "Once upon a time,",
		"max_tokens": 512,
		"temperature": 0.5
	}'

```
