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
# - Interno (ICMP/TCP/UDP) entre subredes
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

# Crear política global y asociarla a la VPC
gcloud compute network-firewall-policies create "${FW_POLICY}" --global

gcloud compute network-firewall-policies associations create \
  --firewall-policy="${FW_POLICY}" --network="${NETWORK}" \
  --name="${FW_POLICY}-assoc" --global-firewall-policy

# ALLOW al bastion SA
gcloud compute network-firewall-policies rules create 100 \
  --firewall-policy="${FW_POLICY}" --direction=EGRESS --action=ALLOW \
  --dest-ip-ranges="${MASTER_CIDR}" --layer4-configs=all \
  --target-service-accounts="${BASTION_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --global-firewall-policy

# DENY a todos los demás
gcloud compute network-firewall-policies rules create 200 \
  --firewall-policy="${FW_POLICY}" --direction=EGRESS --action=DENY \
  --dest-ip-ranges="${MASTER_CIDR}" --layer4-configs=all \
  --global-firewall-policy
