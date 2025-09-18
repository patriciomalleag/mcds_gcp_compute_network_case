# Caso Práctico: Compute and Network - MCDS IMMUNE Institute

## Descripción

Implementación de un clúster GKE privado con bastion host para acceso controlado. El clúster utiliza nodos privados, API privada y Cloud NAT para conectividad de salida. Incluye firewall policies para restringir acceso al control plane solo al bastion host.

## Requisitos Técnicos

- Clúster GKE estándar zonal (no Autopilot)
- Nodos y API privados
- Bastion host como punto de acceso único
- Conectividad de salida a Internet via Cloud NAT
- Firewall policies para seguridad del control plane
- Aplicación expuesta via LoadBalancer

## Arquitectura

- **VPC**: `pm-vpc-secure` con subredes segmentadas
- **Bastion**: VM `e2-medium` en subnet `10.10.0.0/24` con IP pública
- **GKE**: Clúster privado en subnet `10.20.0.0/20` con rangos secundarios para pods/servicios
- **Control Plane**: API privada en `172.16.0.0/28`
- **Cloud NAT**: Router `pm-nat-router` para egreso de pods
- **Firewall Policy**: `pm-vpc-fw-policy` con reglas ALLOW/DENY para control plane

## Direccionamiento IP

| Componente | CIDR | Propósito |
|------------|------|-----------|
| Subnet Bastion | `10.10.0.0/24` | VM bastion |
| Subnet GKE | `10.20.0.0/20` | Nodos GKE |
| Control Plane | `172.16.0.0/28` | API privada |
| Pods | `10.30.0.0/16` | IPs de pods |
| Services | `10.50.0.0/20` | IPs de servicios |

## Firewall Rules

- **Interno**: ICMP/TCP/UDP entre subredes internas
- **SSH**: Puerto 22 al bastion desde `0.0.0.0/0`
- **Policy 100**: ALLOW bastion SA → control plane
- **Policy 200**: DENY todos → control plane

## Service Account

- **Bastion SA**: `pm-bastion-sa` con rol `roles/container.developer`

## Ejecución

```bash
# 1. Configurar variables
source src/00_env.sh

# 2. Crear infraestructura base
./src/01_bootstrap.sh

# 3. Desplegar bastion host
./src/02_bastion.sh

# 4. Crear clúster GKE
./src/03_cluster.sh

# 5. Desplegar aplicación
./src/04_deploy.sh

# 6. Limpiar recursos
./src/99_cleanup.sh
```

## Aplicación

- **Imagen**: `docker.io/istio/examples-helloworld-v1:1.0`
- **Endpoint**: `http://EXTERNAL_IP/hello`
- **Tipo**: LoadBalancer
- **Namespace**: `demo`

## Validación

```bash
# Acceso SSH al bastion
gcloud compute ssh pm-bastion --zone=southamerica-west1-c

# Conectar al clúster desde bastion
gcloud container clusters get-credentials pm-gke-privado --zone=southamerica-west1-c --internal-ip

# Verificar pods
kubectl get pods -n demo

# Obtener IP externa
kubectl get svc helloworld -n demo -o wide

# Probar aplicación
curl http://EXTERNAL_IP/hello
```

## Prerequisitos

- Google Cloud SDK configurado
- Proyecto GCP con billing habilitado
- APIs: Compute Engine, Kubernetes Engine

## Estructura

```
src/
├── 00_env.sh          # Variables
├── 01_bootstrap.sh    # VPC, subredes, NAT
├── 02_bastion.sh      # VM bastion
├── 03_cluster.sh      # Clúster GKE
├── 04_deploy.sh       # Aplicación
├── 99_cleanup.sh      # Limpieza
└── k8s/helloworld.yaml
```

## Troubleshooting

- **Bastion inaccesible**: Verificar firewall SSH
- **Clúster inaccesible**: Verificar credenciales y firewall policy
- **Sin IP externa**: Verificar quotas de LoadBalancer
- **Pods sin Internet**: Verificar Cloud NAT y Private Google Access
