#!/usr/bin/env bash
set -euo pipefail
source ./00_env.sh

# Script de arranque
read -r -d '' STARTUP <<"EOF"
#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y apt-transport-https ca-certificates gnupg curl jq

# gcloud CLI
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee /etc/apt/sources.list.d/google-cloud-sdk.list
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --dearmor > /usr/share/keyrings/cloud.google.gpg
apt-get update -y
apt-get install -y google-cloud-cli

# Plugin de autenticación GKE
# Fallback gcloud si apt falla
apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin || true
echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> /etc/profile.d/gke-auth.sh

# kubectl
KREL=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KREL}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client=true || true
EOF

gcloud compute instances create "${BASTION_NAME}" \
  --zone="${ZONE}" \
  --machine-type="${BASTION_MACHINE}" \
  --image-family=debian-12 --image-project=debian-cloud \
  --subnet="${SUBNET_BASTION}" --tags="bastion" \
  --scopes="https://www.googleapis.com/auth/cloud-platform" \
  --service-account="${BASTION_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --metadata=startup-script="$STARTUP"
