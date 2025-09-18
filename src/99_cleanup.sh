#!/usr/bin/env bash
set -euo pipefail
source ./00_env.sh

# Kubernetes (desde bastion)
gcloud compute ssh "${BASTION_NAME}" --zone "${ZONE}" --command "
  set -euo pipefail
  gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --internal-ip || true
  kubectl delete -f ~/k8s/helloworld.yaml --ignore-not-found=true || true
"

# Clúster
gcloud container clusters delete "${CLUSTER_NAME}" --zone "${ZONE}" --quiet || true

# Bastion
gcloud compute instances delete "${BASTION_NAME}" --zone "${ZONE}" --quiet || true

# Firewall rules
gcloud compute firewall-rules delete "${NETWORK}-gke-nodes-to-master" --quiet || true
gcloud compute firewall-rules delete "${NETWORK}-gke-master-to-nodes" --quiet || true

# NAT y router
gcloud compute routers nats delete "${NAT_NAME}" --router "${ROUTER_NAME}" \
  --router-region "${REGION}" --quiet || true
gcloud compute routers delete "${ROUTER_NAME}" --region "${REGION}" --quiet || true

# Reglas de firewall y subredes
gcloud compute firewall-rules delete "${NETWORK}-ssh-bastion" --quiet || true
gcloud compute firewall-rules delete "${NETWORK}-allow-internal" --quiet || true

gcloud compute networks subnets delete "${SUBNET_GKE}" --region "${REGION}" --quiet || true
gcloud compute networks subnets delete "${SUBNET_BASTION}" --region "${REGION}" --quiet || true
gcloud compute networks delete "${NETWORK}" --quiet || true

# IAM SA
gcloud projects remove-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${BASTION_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.developer" || true
gcloud iam service-accounts delete "${BASTION_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --quiet || true
