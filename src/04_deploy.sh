#!/usr/bin/env bash
set -euo pipefail
source ./00_env.sh

# Manifiestos al bastion
gcloud compute scp --zone "${ZONE}" --recurse ./k8s "${BASTION_NAME}:~/k8s"

# Deploy desde bastion
gcloud compute ssh "${BASTION_NAME}" --zone "${ZONE}" --command "
  set -euo pipefail
  source /etc/profile.d/gke-auth.sh || true
  gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --internal-ip
  kubectl apply -f ~/k8s/helloworld.yaml
  kubectl -n demo wait --for=condition=available deploy/helloworld --timeout=180s
  kubectl -n demo get svc helloworld -o wide
  # Test externo
  IP=\$(kubectl -n demo get svc helloworld -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  if [ -n \"\$IP\" ]; then
    echo \"EXTERNAL_IP=\$IP\"
    curl -sS http://\$IP/hello || true
  else
    echo 'Aún sin EXTERNAL-IP; consulta de nuevo en unos minutos:'
    echo 'kubectl -n demo get svc helloworld -w'
  fi
"
