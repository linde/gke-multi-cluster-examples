

# Deploying Inference Gateway (in terraform)

I was working from [Serve an LLM with GKE Inference Gateway](https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-with-gke-inference-gateway), but modified it some because i didnt want to consume the large GPU instances required to run with the original model and LoRA fine tuning. So, I switched it instead to use [TinyLlama/TinyLlama-1.1B-Chat-v1.0](https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0) and run on smaller instances with lower memory requirements. The result hallucinates a lot, but is equivalent to the original tutorial with respect to Inference Gateway, minus only the [LoRA adaptors](https://cloud.google.com/kubernetes-engine/docs/how-to/deploy-gke-inference-gateway#specify-model-objectives) and model routing based on it (ie based model and lora fine tuned models, respectively).


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

## Applying the Infra Config


```bash
terraform init
terraform plan
terraform apply 
```

# Verification of the workload


```bash
WORKER_PROJ=$(echo google_container_cluster.worker.project  | terraform console | tr -d '"')
WORKER_NAME=$(echo google_container_cluster.worker.name  | terraform console | tr -d '"')
WORKER_LOC=$(echo google_container_cluster.worker.location  | terraform console | tr -d '"')
APP=$(echo local.cluster_app  | terraform console | tr -d '"')
MODEL=$(echo var.model  | terraform console | tr -d '"')

gcloud container clusters get-credentials --project=${WORKER_PROJ} --location=${WORKER_LOC} ${WORKER_NAME}

# wait quite a little while for things to get ready
kubectl wait deployments/${APP} --for=jsonpath='{.status.readyReplicas}' --timeout=10m

kubectl port-forward deployments/${APP} 8000 &

curl -X POST "http://localhost:8000/v1/completions" \
	-H "Content-Type: application/json" --data @- <<EOF
	{
		"model": "${MODEL}",
		"prompt": "Once upon a time, there",
		"max_tokens": 512,
		"temperature": 0.5
	}
EOF

# fg and ctrl-c the kubectl port-forward
	
```

# Verification of the Inference Gateway itself


```bash

IP=$(kubectl get gateway/${APP} -o jsonpath='{.status.addresses[0].value}')

curl -i -X POST "http://${IP}/v1/completions" \
	-H "Content-Type: application/json" --data @- <<EOF
	{
		"model": "${MODEL}",
		"prompt": "Once upon a time, there",
		"max_tokens": 512,
		"temperature": 0.5
	}
EOF

```
