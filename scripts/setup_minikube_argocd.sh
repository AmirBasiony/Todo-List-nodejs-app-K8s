#!/bin/bash

set -e
# EC2_PUBLIC_IP=$1

echo "🚀 Deleting existing Minikube cluster..."
minikube delete

echo "🚀 Starting new Minikube cluster with Docker driver..."
minikube start --driver=docker

echo "📦 Checking Minikube status..."
minikube status

echo "🧱 Creating 'argocd' namespace..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
EOF

echo "📥 Installing ArgoCD core components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD server deployment to become available..."
kubectl wait --for=condition=available --timeout=180s deployment/argocd-server -n argocd

echo "🔧 Patching ArgoCD service to be ClusterIP..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}' || true

echo "🚀 Applying ArgoCD Application manifest..."
kubectl apply -f /home/ubuntu/application.yaml


# Get EC2 public IP from instance metadata or AWS CLI (optional)
if command -v curl &>/dev/null && curl -s http://169.254.169.254/latest/meta-data/public-ipv4 &>/dev/null; then
  EC2_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
else
  EC2_PUBLIC_IP="<YOUR_EC2_PUBLIC_IP_HERE>"
fi


echo "🔑 Getting ArgoCD admin password (default: pod name)..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret   -o jsonpath="{.data.password}" | base64 -d && echo)

echo "🔐 Login with username: admin"
echo "✅ Initial ArgoCD admin password (pod name): $ARGOCD_PASSWORD"


# echo "🚀 Starting ArgoCD port forwarding on port 8888 (mapping to 443 inside cluster)..."
# Kill any existing port-forward on 8888 (optional safety)
lsof -ti:8888 | xargs -r kill

echo
echo "*******************************************************************************"
# Port forward ArgoCD service from inside the cluster (443) to EC2's port 8888
echo   "At a terminal run this line to makePort forward ArgoCD service from inside the cluster"
echo   ssh -i todo-app-ssh-key.pem  ubuntu@$EC2_PUBLIC_IP 
echo  "kubectl port-forward svc/argocd-server -n argocd 8888:443 > /dev/null 2>&1 &"
echo "*******************************************************************************"

echo "At Another terminal run this line to accesss ArgoCD from your LocalHost"
echo   ssh -i todo-app-ssh-key.pem  -L 8888:localhost:8888 ubuntu@$EC2_PUBLIC_IP 
echo "*******************************************************************************"

echo "🌐 ArgoCD is now accessible at: http://localhost:8888"
echo "*******************************************************************************"

echo kubectl create secret docker-registry ecr-creds
kubectl create secret docker-registry ecr-creds \
  --namespace=todo-list-app \
  --docker-server=875506561855.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region us-east-1)"

