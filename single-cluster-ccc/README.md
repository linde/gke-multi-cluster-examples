

# Example project with CCC and a workload using it

While not strictly a multi-cluster example, Custom Compute Class and HPA are 
very useful and come up in platform conversations, so this example might be
of interest.


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

kubectl get pods,nodes
```

## Generate some load and see it scale out

If you want to just see scaling, there are two ways. The first works out of the box and is scale via `process_open_fds`. To see this, just apply some load using the `/sleep` endpoint in the examples below. These sleeping connections with increase the process file descriptor count and because of our thresholds we will scale replicas fast and consequently, nodes because the instances are small relative to the workload requests.

```bash
# proxy to the clusters service and generate some load
kubectl port-forward services/webapp-service 8080:8080 
# in a different terminal
hey -n 10000 -c 75  http://localhost:8080/sleep/5 


# see the pods spread to different nodes
kubectl get pods -o json | jq '.items[].spec.nodeName' | uniq -c | sort -rn

# once the nodes scale up, see the distribution matches the ccc
kubectl get nodes -ojson | jq '.items[].metadata.labels["beta.kubernetes.io/instance-type"]'  | uniq -c

```

The webapp also has a way to manually bump and unbump the metric value, for example:

```
http://127.0.0.1:8080/bump

# or bump by a specific amount
http://127.0.0.1:8080/bump/10

# decrement is also supported
http://127.0.0.1:8080/unbump
http://127.0.0.1:8080/unbump/10


```

You can scale based on this by changing the the [04-hpa.yaml](./helm-charts/ccc-example/templates/04-hpa.yaml) file to set the metric to be `prometheus.googleapis.com|process_open_fds|gauge` and applying (you might need to rev the helm chart version). Once the hpa is changes, the replicas (and consequently, nodes) will react to your `curl` bumps and unbump decrements.
