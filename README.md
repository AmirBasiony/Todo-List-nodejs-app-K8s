## 📦 Application Overview

A full-stack, containerized To-Do List application using **Node.js**, **Express.js**, **MongoDB**, and **Docker**, deployed on **Amazon EKS-like architecture (Kind on EC2)** with **ArgoCD GitOps**, fully automated via **Terraform**, **Ansible**, and **GitHub Actions**.

It supports features like `creating`, `editing`, `completing`, and `deleting` tasks.

---

## Table of Contents

* [Tech Stack](#tech-stack)
* [Project Architecture](#project-architecture)
* [Running the Application Locally](#running-the-application-locally)
* [Running with Docker](#running-with-docker)
* [Kubernetes & GitOps Deployment](#kubernetes--gitops-deployment)
* [CI/CD Pipeline](#cicd-pipeline)
* [Infrastructure Architecture](#infrastructure-architecture)
* [Accessing the Application & ArgoCD](#accessing-the-application--argocd)
* [Destroying the Infrastructure](#destroying-the-infrastructure)
* [Final Notes](#final-notes)

---

## Tech Stack

* **Frontend/Backend**: Node.js, Express.js, EJS, CSS
* **Database**: MongoDB with Mongoose
* **Containerization**: Docker
* **Infrastructure as Code**: Terraform
* **Configuration Management**: Ansible
* **CI/CD**: GitHub Actions + ArgoCD (GitOps)
* **Cloud Provider**: AWS (EC2, ECR, VPC, IAM)

---

## Project Architecture

```bash
.
├── Ansible_Roles/             # Playbooks to install Docker, AWS CLI, Kubectl, Kind
├── ArgoCD-Apps/               # ArgoCD Application manifests
├── assets/                    # Static CSS/JS files
├── config/                    # MongoDB connection config
├── controllers/               # App logic
├── models/                    # Mongoose models
├── routes/                    # Express.js routes
├── scripts/                   # Infra build/setup/destroy scripts
├── terraform/                 # Infrastructure provisioning
├── views/                     # EJS views/templates
├── Dockerfile                 # App Dockerfile
├── README.md                  # Documentation
├── index.js                   # App entry point
├── package.json               # App dependencies
````

---

## Running the Application Locally

```bash
git clone https://github.com/AmirBasiony/Todo-List-nodejs-app-K8s.git
cd Todo-List-nodejs-app-K8s
npm install
npm start
```

Ensure MongoDB is running on `mongodb://localhost:27017/todolistDb`

Visit: [http://localhost:4000](http://localhost:4000)

---

## Running with Docker

```bash
docker build -t todo-app-image .
docker run -p 4000:4000 -e mongoDbUrl='mongodb://localhost:27017/todolistDb' todo-app-image
```

---

## Kubernetes & GitOps Deployment

This project is deployed on a **Kind cluster running inside EC2**, managed by **ArgoCD**. Deployment YAMLs are stored in a [GitOps repository](https://github.com/AmirBasiony/todo-list-GitOps-ArgoCD-K8s).


### GitOps Flow

* ArgoCD monitors the GitOps repo.
* Every time the deployment YAML is updated with a new image tag, ArgoCD applies it to the cluster.

---

## CI/CD Pipeline

### ✅ Trigger

On push to the `main` branch.

### 🛠️ Jobs Overview

#### 1. **Build and Push Docker Image**

* Docker image is built with tag: `v<package.json version>.<GitHub run number>`
* Pushed to Amazon ECR:

  ```
  <AWS_ACCOUNT_ID>.dkr.ecr.<region>.amazonaws.com/todo-nodejs-app
  ```

#### 2. **Update GitOps Repo**

* GitHub Action clones the GitOps repo
* Updates the `todo-app_deployment.yaml` with the new image tag
* Commits and pushes back to the GitOps repo
* ArgoCD auto-syncs and updates the running app

### 📄 CI File: `.github/workflows/main.yml`

```yaml
- Build Docker image with dynamic version
- Push image to ECR
- Update deployment YAML in GitOps repo
```

---

## Infrastructure Architecture

Provisioned using **Terraform**, configured using **Ansible**.

### 1️⃣ Terraform

Creates:

* VPC, Subnets
* EC2 (Kind cluster)
* Security groups
* ECR repo
* IAM roles

### 2️⃣ Ansible

* Connects to EC2 via **SSH**
* Installs:

  * Docker
  * AWS CLI
  * kubectl
  * Kind (local Kubernetes)
* Deploys ArgoCD

### 3️⃣ GitHub Actions

* Builds and pushes Docker image to ECR
* Triggers deployment via GitOps model

---

## Accessing the Application & ArgoCD

### 🔐 SSH into the EC2 Instance

```bash
ssh -i todo-app-ssh-key.pem ubuntu@13.221.112.71
```

---

### 🎯 Access ArgoCD Dashboard

In your SSH session or a new terminal:

```bash
kubectl port-forward --address=0.0.0.0 svc/argocd-server 8888:80 -n argocd
```

* 🌐 Open your browser and go to: [http://13.221.112.71:8888](http://13.221.112.71:8888)

    ArgoCD dashboard may also be exposed for visualizing GitOps sync status.

---

### 📝 Access the Todo List App

In your SSH session or a new terminal:

```bash
kubectl port-forward --address=0.0.0.0 service/todo-service 8080:4000 -n todo-list-app
```

* 🌐 Open your browser and go to: [http://13.221.112.71:8080](http://13.221.112.71:8080)

---

## Destroying the Infrastructure

```bash
cd scripts/
./infra_destroy.sh
```

Cleans up all resources via `terraform destroy`.

---

## Final Notes

* ✅ GitOps-ready CI/CD with ArgoCD + GitHub Actions
* ✅ Secure provisioning via Terraform & Ansible (via SSH)
* ✅ Clean and modular structure
* ✅ Built for extensibility on AWS-native services

---

🧑‍💻 Developed by **Amir Basiony**
📨 [LinkedIn](https://www.linkedin.com/in/amir-elbasiony-57809b204/)

```