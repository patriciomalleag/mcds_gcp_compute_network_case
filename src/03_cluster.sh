#!/usr/bin/env bash
set -euo pipefail
source ./00_env.sh

# Clúster privado con VPC nativa
gcloud container clusters create "${CLUSTER_NAME}" \
  --zone "${ZONE}" \
  --num-nodes "2" \
  --machine-type "e2-standard-2" \
  --enable-ip-alias \
  --network "${NETWORK}" \
  --subnetwork "${SUBNET_GKE}" \
  --cluster-secondary-range-name "${POD_RANGE_NAME}" \
  --services-secondary-range-name "${SVC_RANGE_NAME}" \
  --enable-private-nodes \
  --enable-private-endpoint \
  --master-ipv4-cidr "${MASTER_CIDR}" \
  --enable-master-authorized-networks \
  --master-authorized-networks "${SUBNET_BASTION_RANGE}"
