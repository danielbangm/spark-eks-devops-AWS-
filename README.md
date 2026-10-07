# Spark — AWS EKS DevOps & GitOps Deployment

A cloud-native deployment project demonstrating how to containerize a Python Flask web application, provision AWS infrastructure with Terraform, deploy to Amazon EKS, configure Kubernetes autoscaling, and automate deployments using Jenkins and GitHub Actions with Argo CD.

## Project Overview

**Spark** is a fictional dating application landing page built with Python Flask. The application is deployed as a Docker container on Amazon Elastic Kubernetes Service (EKS), with an AWS Application Load Balancer providing public access.

The project implements two CI/CD approaches:

1. **Jenkins CI/CD:** Build a Docker image, push it to Amazon ECR, and deploy it to EKS using Helm.
2. **GitHub Actions + Argo CD GitOps:** Build and push a versioned image, update the GitOps branch, and automatically synchronize the Kubernetes deployment through Argo CD.

## Technology Stack

| Category | Technology |
|---|---|
| Application | Python, Flask, HTML, CSS |
| Containerization | Docker |
| Infrastructure as Code | Terraform |
| Cloud Provider | AWS |
| Container Registry | Amazon ECR |
| Container Orchestration | Amazon EKS, Kubernetes |
| Package Management | Helm |
| CI/CD | Jenkins, GitHub Actions |
| GitOps | Argo CD |
| Load Balancing | AWS Application Load Balancer |
| Autoscaling | Horizontal Pod Autoscaler, Cluster Autoscaler |
| Metrics | Kubernetes Metrics Server |
| Version Control | Git, GitHub |

## Architecture

```text
                       GitHub Repository
                              |
                 +------------+------------+
                 |                         |
              Jenkins                GitHub Actions
                 |                         |
            Docker Build               Docker Build
                 |                         |
                 +------------+------------+
                              |
                         Amazon ECR
                              |
                   +----------+----------+
                   |                     |
             Jenkins CD              GitOps Branch
                   |                     |
              Helm Upgrade              Argo CD
                   |                     |
                   +----------+----------+
                              |
                         Amazon EKS
                              |
                        Spark Deployment
                              |
                     Kubernetes Service
                              |
                    AWS Application Load
                          Balancer
                              |
                            Users
```

**Note:** Jenkins CD and Argo CD represent separate deployment approaches. Argo CD is responsible for synchronizing deployments in the GitOps workflow.

## AWS Infrastructure

Terraform provisions the primary AWS infrastructure, including:

- A VPC with CIDR `10.0.0.0/16`.
- Two public subnets across separate Availability Zones.
- Two private subnets across separate Availability Zones.
- Internet Gateway and public routing.
- NAT Gateway for outbound connectivity from private subnets.
- Amazon EKS cluster named `spark-cluster`.
- EKS managed node group using `t3.small` EC2 instances.
- Amazon ECR repository named `spark`.
- IAM roles and policies for EKS cluster and worker nodes.

The EKS worker nodes are deployed in private subnets, while the internet-facing Application Load Balancer provides public access to the application.

### Node Scaling Configuration

| Setting | Value |
|---|---|
| EC2 instance type | t3.small |
| Minimum nodes | 1 |
| Desired nodes | 1 |
| Maximum nodes | 4 |
| Availability Zones | us-east-1a, us-east-1b |

Cluster Autoscaler is installed to manage worker-node capacity when Kubernetes pods cannot be scheduled due to insufficient resources.

## Application and Docker

The Flask application provides the following endpoints:

| Endpoint | Description |
|---|---|
| `/` | Spark landing page |
| `/health` | Application health check |
| `/api/info` | Application name, version, and container hostname |

### Build and Run Locally

From the project root:

```bash
cd app
docker build -t spark:v1 .
docker run -d --name spark-container -p 5000:5000 spark:v1
```

Access the application:

```text
http://localhost:5000
```

Test its health endpoint:

```bash
curl http://localhost:5000/health
```

## Terraform Deployment

Prerequisites:

- AWS account with appropriate permissions
- AWS CLI configured
- Terraform installed
- kubectl installed
- Helm installed
- Docker installed

From the project root:

```bash
cd terraform

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Configure kubectl:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name spark-cluster
```

Verify connectivity:

```bash
kubectl get nodes
```

**Important:** Terraform provisions the core infrastructure. Additional cluster components, including the AWS Load Balancer Controller, Metrics Server, Cluster Autoscaler, and Argo CD, were installed and configured separately.

## Kubernetes Deployment with Helm

The Helm chart is located at:

```text
helm/spark/
```

It contains Kubernetes manifests for the Spark Deployment, Service, Ingress, Horizontal Pod Autoscaler, and supporting resources.

Deploy the application:

```bash
helm upgrade --install spark ./helm/spark \
  --namespace default
```

Verify:

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl get hpa
```

The application is exposed through an AWS Application Load Balancer managed by the AWS Load Balancer Controller.

## Kubernetes Autoscaling

The deployment includes two scaling mechanisms.

### Horizontal Pod Autoscaler (HPA)

The HPA adjusts the number of Spark pods based on resource utilization.

| Setting | Value |
|---|---|
| Minimum replicas | 1 |
| Maximum replicas | 3 |
| CPU utilization target | 50% |
| Memory utilization target | 50% |

Kubernetes Metrics Server supplies resource metrics to the HPA.

### Cluster Autoscaler

Cluster Autoscaler manages the number of EC2 worker nodes within the managed node group's configured limits of 1–4 nodes.

HPA scales application pods, while Cluster Autoscaler increases available node capacity when additional pods cannot be scheduled.

Both components have been installed and configured. A dedicated scaling load test is planned for a future project update.

## Jenkins CI/CD Pipeline

The Jenkins pipeline is defined in the repository's `Jenkinsfile`.

Jenkins runs in a Docker container on an EC2 instance and uses an IAM instance role for AWS authentication.

### Pipeline Stages

1. Checkout application source code from GitHub.
2. Build the Docker image.
3. Authenticate to Amazon ECR.
4. Push the versioned image to ECR.
5. Configure access to Amazon EKS.
6. Deploy the application using Helm.
7. Verify Kubernetes resources.

The pipeline uses the Jenkins build number as the Docker image tag.

**Result:** The Jenkins pipeline successfully built, pushed, and deployed Spark to Amazon EKS.

## GitOps with GitHub Actions and Argo CD

The project also implements a GitOps-based deployment workflow using a separate `gitops` branch.

### GitHub Actions Workflow

The workflow is located at:

```text
.github/workflows/gitops.yml
```

It performs the following actions:

1. Checkout the source code from `main`.
2. Authenticate to AWS using GitHub repository secrets.
3. Build the Spark Docker image.
4. Tag the image using the Git commit SHA.
5. Push the image to Amazon ECR.
6. Update the image tag in `helm/spark/values.yaml` on the `gitops` branch.
7. Commit and push the updated GitOps configuration.

### Argo CD Continuous Deployment

Argo CD runs inside the EKS cluster and monitors:

```text
Repository: spark-eks-devops
Branch: gitops
Path: helm/spark
Namespace: default
```

Automatic synchronization, pruning, and self-healing are enabled.

When GitHub Actions updates the image tag in the `gitops` branch, Argo CD detects the change and synchronizes the Kubernetes deployment.

**Result:** GitHub Actions completed successfully, and the Spark application was deployed with a commit-SHA-tagged container image. The Argo CD application reached Synced and Healthy status during verification.

## Project Structure

```text
Dating-app-project/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── templates/
│   │   └── index.html
│   └── static/
│       └── style.css
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── eks.tf
│   ├── ecr.tf
│   └── outputs.tf
├── helm/
│   └── spark/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── .github/
│   └── workflows/
│       └── gitops.yml
├── Jenkinsfile
├── cluster-autoscaler-policy.json
├── .gitignore
└── README.md
```

## Deployment Verification

The following components were verified during implementation:

- Terraform successfully provisioned the EKS infrastructure.
- EKS worker node reached Ready status.
- Docker image was pushed to Amazon ECR.
- Spark was accessible through the AWS Application Load Balancer.
- Kubernetes Metrics Server provided CPU and memory utilization metrics.
- Horizontal Pod Autoscaler was configured with CPU and memory targets.
- Cluster Autoscaler pod reached Running status.
- Jenkins pipeline completed successfully.
- GitHub Actions GitOps pipeline completed successfully.
- Argo CD reached Synced and Healthy status.
- Spark application pod reached `1/1 Running`.

## Future Improvements

- Integrate Amazon CloudWatch for AWS infrastructure monitoring.
- Deploy Prometheus and Grafana for Kubernetes observability.
- Create dashboards for CPU, memory, pod health, and application performance.
- Conduct load testing to demonstrate HPA and Cluster Autoscaler behavior.
- Add automated testing and additional deployment safeguards.
- Replace long-lived GitHub Actions AWS credentials with IAM OIDC federation.

## Resource Cleanup

AWS resources such as EKS, EC2, NAT Gateway, and Application Load Balancers may incur charges while running.

When the lab is no longer needed, remove Kubernetes and separately installed AWS resources before destroying the Terraform-managed infrastructure.

Run `terraform destroy` from the Terraform directory only after confirming that the environment is no longer required.

## Project Status

**Core deployment and GitOps implementation: Complete**

**Observability and load-testing enhancements: Planned**

This project demonstrates containerized application delivery, AWS infrastructure provisioning, Kubernetes orchestration, autoscaling configuration, and automated deployments using both traditional CI/CD and GitOps practices.
