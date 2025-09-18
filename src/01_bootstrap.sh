#!/usr/bin/env bash
set -euo pipefail
source ./00_env.sh
gcloud config set project "${PROJECT_ID}"

# APIs
gcloud services enable compute.googleapis.com container.googleapis.com

# VPC y subredes
gcloud compute networks create "${NETWORK}" --subnet-mode=custom

gcloud compute networks subnets create "${SUBNET_BASTION}" \
  --network="${NETWORK}" --region="${REGION}" --range="${SUBNET_BASTION_RANGE}"

gcloud compute networks subnets create "${SUBNET_GKE}" \
  --network="${NETWORK}" --region="${REGION}" --range="${SUBNET_GKE_RANGE}" \
  --secondary-range="${POD_RANGE_NAME}=${POD_RANGE_CIDR},${SVC_RANGE_NAME}=${SVC_RANGE_CIDR}"

# Private Google Access
gcloud compute networks subnets update "${SUBNET_GKE}" \
  --region "${REGION}" --enable-private-ip-google-access

# Reglas de firewall básicas
# - Interno entre subredes
gcloud compute firewall-rules create "${NETWORK}-allow-internal" \
  --network="${NETWORK}" --allow tcp,udp,icmp \
  --source-ranges="${SUBNET_BASTION_RANGE},${SUBNET_GKE_RANGE}"

# - SSH al bastion
gcloud compute firewall-rules create "${NETWORK}-ssh-bastion" \
  --network="${NETWORK}" --allow tcp:22 --source-ranges="${ALLOWED_SSH_CIDR}" \
  --target-tags="bastion"

# Service Account del bastion
gcloud iam service-accounts create "${BASTION_SA}" \
  --display-name="Bastion SA"

# Para propagar, pq me falló la primera vez
sleep 15

# Permisos mínimos para operar con el clúster
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${BASTION_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.developer"

# Cloud Router + NAT para egreso de pods
gcloud compute routers create "${ROUTER_NAME}" \
  --network="${NETWORK}" --region="${REGION}"

gcloud compute routers nats create "${NAT_NAME}" \
  --router-region="${REGION}" --router="${ROUTER_NAME}" \
  --nat-all-subnet-ip-ranges --auto-allocate-nat-external-ips

# Firewall para GKE - Nodos a Control Plane
gcloud compute firewall-rules create "${NETWORK}-gke-nodes-to-master" \
  --network="${NETWORK}" --allow tcp:443,tcp:10250 \
  --source-ranges="${SUBNET_GKE_RANGE}" \
  --target-tags="gke-node"

# Firewall para GKE - Control Plane a Nodos  
gcloud compute firewall-rules create "${NETWORK}-gke-master-to-nodes" \
  --network="${NETWORK}" --allow tcp:10250,tcp:443 \
  --source-ranges="${MASTER_CIDR}" \
  --target-tags="gke-node"
