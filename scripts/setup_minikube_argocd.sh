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



# # Step 1: Clean up and start Minikube
# section_header "*******************    Deleting existing Minikube cluster    ******************"
# minikube delete

# section_header "*******************     Starting new Minikube cluster      ********************"
# minikube start --driver=docker --cpus=2 --memory=2200mb --disk-size=20g

# section_header "*******************       Verifying Minikube status        ********************"
# minikube status


# Define Kind cluster name
CLUSTER_NAME="todo-list-cluster"

# Step 1: Check if Kind cluster exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  section_header "****** Kind cluster '${CLUSTER_NAME}' already exists. Skipping creation *****" "1"
else
  section_header "*************** Creating new Kind cluster: ${CLUSTER_NAME}  *****************"
  kind create cluster --name "$CLUSTER_NAME"
fi

# Step 2: Export kubeconfig path (important in automation or headless environments)
# export KUBECONFIG="$(kind get kubeconfig-path --name="$CLUSTER_NAME" 2>/dev/null || echo "${HOME}/.kube/config")"

# Step 3: Verify Kind cluster is running
section_header "********************     Verifying Kind cluster status     ********************"
# sudo kubectl config use-context kind-${CLUSTER_NAME}
kind export kubeconfig --name "$CLUSTER_NAME"

kubectl cluster-info --context kind-"$CLUSTER_NAME"
kubectl get nodes --context kind-"$CLUSTER_NAME" -o wide


# Step 4: Install ArgoCD
section_header "*******************        Creating 'argocd' namespace      *******************" "1"
kubectl create namespace argocd

section_header "*******************   Installing ArgoCD core components     *******************"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

section_header "***************    Waiting for ArgoCD server to be available    ***************"
kubectl wait --for=condition=available --timeout=180s deployment/argocd-server -n argocd

section_header "*******************   Patching ArgoCD service to ClusterIP   ******************"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}' || true

section_header "********************  Applying ArgoCD Application manifest  *******************"
kubectl apply -f /home/ubuntu/application.yaml

# Step 5: Access Info
section_header "**********************  Fetching ArgoCD credentials  **************************"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD Username: admin"
echo "ArgoCD Initial Password: $ARGOCD_PASSWORD"

# Step 6: Port forwarding instructions
section_header "**********************     Port Forward Instructions     **********************"

echo "To access ArgoCD (in one terminal):"
echo "ssh -i todo-app-ssh-key.pem ubuntu@$EC2_PUBLIC_IP"
echo "kubectl port-forward --address=0.0.0.0 svc/argocd-server 8888:80 -n argocd"

echo -e "\nThen on your local terminal:"
echo "ssh -i todo-app-ssh-key.pem -L 8888:localhost:8888 ubuntu@$EC2_PUBLIC_IP"
echo "Open in browser: http://localhost:8888"

echo -e "\nTo access your Node app (in another terminal):"
echo "ssh -i todo-app-ssh-key.pem ubuntu@$EC2_PUBLIC_IP"
echo "kubectl port-forward --address=0.0.0.0 svc/todo-service 8080:4000 -n todo-list-app"

echo -e "\nOn your local:"
echo "ssh -i todo-app-ssh-key.pem -L 8080:localhost:8080 ubuntu@$EC2_PUBLIC_IP"
echo "Open in browser: http://localhost:8080"

# section_header "*********************  Creating ECR Docker registry secret  *******************"

# Step 5: Setup App Namespace and Secrets for the application
section_header "*******  Creating 'todo-list-app' namespace & ECR Docker registry secret ******" "1"
kubectl create namespace todo-list-app
kubectl create secret docker-registry ecr-creds \
  --namespace=todo-list-app \
  --docker-server=875506561855.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region us-east-1)"

section_header "**************   Kind & ArgoCD Setup Completed Successfully   *************"
