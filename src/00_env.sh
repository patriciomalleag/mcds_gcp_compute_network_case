#!/usr/bin/env bash
set -euo pipefail

# Proyecto y ubicación
export PROJECT_ID="patriciomallea-2503"
export REGION="southamerica-west1"
export ZONE="southamerica-west1-c"

# Red
export NETWORK="pm-vpc-secure"
export SUBNET_BASTION="pm-subnet-bastion"
export SUBNET_BASTION_RANGE="10.10.0.0/24"
export SUBNET_GKE="pm-subnet-gke"
export SUBNET_GKE_RANGE="10.20.0.0/20"

# Rango del control plane
export MASTER_CIDR="172.16.0.0/28"

# Rangos secundarios para VPC nativa
export POD_RANGE_NAME="pm-gke-pods"
export POD_RANGE_CIDR="10.30.0.0/16"
export SVC_RANGE_NAME="pm-gke-services"
export SVC_RANGE_CIDR="10.50.0.0/20"

# NAT
export ROUTER_NAME="pm-nat-router"
export NAT_NAME="nat-config"

# Bastion
export BASTION_NAME="pm-bastion"
export BASTION_MACHINE="e2-medium"
export BASTION_SA="pm-bastion-sa"
export ALLOWED_SSH_CIDR="0.0.0.0/0"

# GKE
export CLUSTER_NAME="pm-gke-privado"

# Firewall
export FW_POLICY="pm-vpc-fw-policy"
