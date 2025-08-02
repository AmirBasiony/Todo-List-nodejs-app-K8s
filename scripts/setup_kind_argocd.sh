#!/bin/bash
set -e

# Function to display section headers centered
function section_header {
  if [[ "$2" == "1" ]]; then
    echo "*******************************************************************************"
    echo "$1"
  else
    echo "*******************************************************************************"
    echo "$1"
    echo "*******************************************************************************"
  fi
}

# Fetch EC2 public IP from metadata if possible
if command -v curl &>/dev/null && curl -s http://169.254.169.254/latest/meta-data/public-ipv4 &>/dev/null; then
  EC2_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
else
  EC2_PUBLIC_IP="<YOUR_EC2_PUBLIC_IP_HERE>"
fi

# Define Kind cluster name
CLUSTER_NAME="todo-list-cluster"

# Step 1: Check if Kind cluster exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  section_header "****** Kind cluster '${CLUSTER_NAME}' already exists. Skipping creation *****" "1"
else
  section_header "*************** Creating new Kind cluster: ${CLUSTER_NAME}  *****************" "1"
  kind create cluster --name "$CLUSTER_NAME" --config ~/kind-config.yaml

fi

# Step 3: Verify Kind cluster is running
section_header "********************     Verifying Kind cluster status     ********************"
kind export kubeconfig --name "$CLUSTER_NAME"
kubectl cluster-info --context kind-"$CLUSTER_NAME"
kubectl get nodes --context kind-"$CLUSTER_NAME" #-o wide


# Step 4: Install ArgoCD
section_header "*******************        Creating 'argocd' namespace      *******************" "1"
if ! kubectl get namespace argocd >/dev/null 2>&1; then
  kubectl create namespace argocd
else
  echo "Namespace 'argocd' already exists. Skipping creation."
fi

section_header "*******************   Installing ArgoCD core components     *******************"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

section_header "***************    Waiting for ArgoCD server to be available    ***************" "1"
kubectl wait --for=condition=available --timeout=180s deployment/argocd-server -n argocd

section_header "*******************   Patching ArgoCD service to ClusterIP   ******************" "1"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}' || true

section_header "********************  Applying ArgoCD Application manifest  *******************" "1"
kubectl apply -f /home/ubuntu/application.yaml

# Step 5: Access Info
section_header "**********************  Fetching ArgoCD credentials  **************************" "1"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD Username: admin"
echo "ArgoCD Initial Password: $ARGOCD_PASSWORD"

# Step 6: Port forwarding instructions
section_header "**********************     Port Forward Instructions     **********************" "1"

echo "To access ArgoCD (in one terminal):"
echo "ssh -i todo-app-ssh-key.pem ubuntu@$EC2_PUBLIC_IP"
echo "kubectl port-forward --address=0.0.0.0 svc/argocd-server 8888:80 -n argocd"
echo "Open in browser: http://$EC2_PUBLIC_IP:8888"

echo  "To access The Todo-list app:"
echo "ssh -i todo-app-ssh-key.pem ubuntu@$EC2_PUBLIC_IP"
echo "kubectl port-forward --address=0.0.0.0 service/todo-service 8080:4000 -n todo-list-app"
echo "Open in browser: http://$EC2_PUBLIC_IP:8080"

# Step 5: Setup App Namespace and Secrets for the application
section_header "*******  Creating 'todo-list-app' namespace & ECR Docker registry secret ******" "1"
# Create 'argocd' namespace if it doesn't exist
section_header "*******************        Creating 'argocd' namespace      *******************" "1"
if ! kubectl get namespace argocd >/dev/null 2>&1; then
  kubectl create namespace argocd
else
  echo "Namespace 'argocd' already exists. Skipping creation."
fi

# Create 'todo-list-app' namespace if it doesn't exist
section_header "*******  Creating 'todo-list-app' namespace & ECR Docker registry secret ******" "1"
if ! kubectl get namespace todo-list-app >/dev/null 2>&1; then
  kubectl create namespace todo-list-app
else
  echo "Namespace 'todo-list-app' already exists. Skipping creation."
fi

# Create ECR docker-registry secret if it doesn't exist
if ! kubectl get secret ecr-creds -n todo-list-app >/dev/null 2>&1; then
  kubectl create secret docker-registry ecr-creds \
    --namespace=todo-list-app \
    --docker-server=875506561855.dkr.ecr.us-east-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password="$(aws ecr get-login-password --region us-east-1)"
else
  echo "Secret 'ecr-creds' already exists in 'todo-list-app'. Skipping creation."
fi


section_header "****************   Kind & ArgoCD Setup Completed Successfully   ***************" "1"
