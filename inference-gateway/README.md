

# Deploying Inference Gateway (in terraform)

I was working from [Serve an LLM with GKE Inference Gateway](https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-with-gke-inference-gateway), but modified it some because i didnt want to consume the large GPU instances required to run with the original model and lora fine tuning.

I switched it instead to use [TinyLlama/TinyLlama-1.1B-Chat-v1.0](https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0) and run on smaller instances with lower memory requirements.


## Setup

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

```

## Model Access

FYI -- they are not kidding around with this tutorial step: [Get access to the model](https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-with-gke-inference-gateway#model-access). I glossed over this and took a while to find the helpful error messages to this effect 
when things weren't coming up cleanly.  Meta's acceptance of your application might take a while, so plan accordingly.


## Applying the Infra Config


```bash
terraform init
terraform plan
terraform apply 
```

# Verification


```bash
WORKER_PROJ=$(echo google_container_cluster.worker.project  | terraform console | tr -d '"')
WORKER_NAME=$(echo google_container_cluster.worker.name  | terraform console | tr -d '"')
WORKER_LOC=$(echo google_container_cluster.worker.location  | terraform console | tr -d '"')
gcloud container clusters get-credentials --project=${WORKER_PROJ} --location=${WORKER_LOC} ${WORKER_NAME}


# wait quite a little while for things to get ready
kubectl wait --for=condition=Ready deployment/vllm-llama3-8b-instruct --timeout=20m

kubectl port-forward deployments/vllm-llama3-8b-instruct 8000 &

curl -X POST "http://localhost:8000/v1/completions" \
	-H "Content-Type: application/json" \
	--data '{
		"model": "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
		"prompt": "Once upon a time,",
		"max_tokens": 512,
		"temperature": 0.5
	}'
```
