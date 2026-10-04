# Automate Kubernetes Deployment — Complete Implementation Runbook

## Purpose

This runbook is the complete, standalone implementation guide for the **Automate Kubernetes Deployment** capstone project.

It is written so the project can be recreated from a fresh local environment. 

The project provisions Amazon EKS with Terraform, configures local Kubernetes access, then uses Ansible to create a new Kubernetes namespace and deploy an Nginx application.

---

# 1. Project Requirements

The capstone requires:

1. Create an Amazon EKS cluster using Terraform.
2. Write an Ansible playbook that deploys an application into a new Kubernetes namespace.
3. Configure Kubernetes access so Ansible can communicate with the EKS cluster.

The required technology scope is therefore:

```text
Terraform
AWS
Amazon EKS
Kubernetes
Ansible
Python
Linux / Unix shell
AWS CLI
kubectl
Git
```

The assignment does not require Jenkins, ECR, Nexus, Prometheus, Grafana, RDS, or a CI/CD pipeline, so they are not added to the baseline implementation.

---

# 2. Source and Implementation Boundaries

Training reference:

```text
TechWorld with Nana — DevOps Bootcamp — Module 15: Ansible
```

Relevant training concepts include:

```text
Ansible playbooks
Ansible modules and collections
Ansible variables
Terraform and Ansible
Deploying applications into Kubernetes with Ansible
```

The capstone requirements control the project. Training examples are used as implementation guidance rather than copied blindly.

The Terraform configuration, Ansible project, Kubernetes resources, security decisions, troubleshooting, Git workflow, testing, and documentation in this repository are implemented independently for this capstone.

---

# 3. Final Architecture

```text
Local macOS Control Machine
│
├── Terraform
│   │
│   └── AWS
│       ├── VPC 10.0.0.0/16
│       ├── Public Subnet 10.0.1.0/24
│       ├── Public Subnet 10.0.2.0/24
│       ├── Internet Gateway
│       ├── Public route table
│       └── Amazon EKS 1.36
│           ├── Managed node group
│           │   └── 1 x t3.small
│           ├── CoreDNS
│           ├── kube-proxy
│           └── VPC CNI
│
├── AWS CLI
│   └── aws eks update-kubeconfig
│
├── kubectl
│   └── EKS verification
│
└── Ansible
    └── kubernetes.core.k8s
        ├── Namespace: my-app
        ├── Deployment: nginx
        │   └── 2 replicas
        └── Service: nginx-service
            └── ClusterIP :80
```

---

# 4. Engineering Principles

## 4.1 Requirement First

```text
assignment requirements
→ relevant Nana method
→ existing project code
→ minimum compatibility/security adaptation
→ optional production improvements later
```

## 4.2 Cost Control

Prepare everything possible locally before creating chargeable infrastructure:

```text
requirements
→ repository
→ Terraform code
→ Ansible code
→ local validation
→ AWS preflight
→ terraform plan
→ terraform apply
→ deploy
→ verify
→ terraform destroy
```

The final design intentionally avoids:

```text
NAT Gateway
AWS Load Balancer
RDS
ECR
custom KMS key
CloudWatch EKS control-plane log group
IRSA/OIDC provider
Jenkins infrastructure
```

## 4.3 Security

Never commit:

```text
AWS access keys
AWS secret access keys
private keys
real terraform.tfvars
Terraform state
kubeconfig
other credentials or secrets
```

The EKS public endpoint is restricted to the operator's current public IPv4 address using `/32` CIDR.

---

# 5. Verified Development Environment

This implementation was completed with:

```text
macOS:                    26.2
Architecture:             arm64
Shell:                    zsh
Git:                      2.52.0
Homebrew:                 6.0.22
Terraform:                1.15.6
AWS CLI:                  2.34.36
kubectl:                  1.37.0
Ansible Core:             2.21.3
Ansible package:          14.3.1
kubernetes.core:          6.5.0
System Python:            3.12.10
Ansible Python:           3.14.7
Kubernetes Python client: 36.0.3
PyYAML:                   6.0.3
jsonpatch:                1.33
```

Compatible newer versions may also work, but the versions above are the ones verified during this implementation.

The Terraform configuration requires:

```text
Terraform >= 1.15.0
AWS provider >= 6.59 and < 7.0
```

---

# 6. Local Workspace and Repository Setup

Create the project workspace:

```bash
cd ~/Documents/tech-workspace/devops-capstone-projects
mkdir -p automate-kubernetes-deployment
cd automate-kubernetes-deployment
```

Initialize Git:

```bash
git init
git branch -M main
```

Create initial directories:

```bash
mkdir -p terraform
mkdir -p ansible/manifests
```

Create the two remote repositories as empty repositories, then configure them:

```bash
git remote add github https://github.com/younghadiz/automate-kubernetes-deployment.git
git remote add gitlab https://gitlab.com/devops-engineering-projects/automate-kubernetes-deployment.git
```

Verify:

```bash
git remote -v
```

GitHub is the primary remote. GitLab is the mirror.

---

# 7. Git Branching Model

Use:

```text
main
  └── develop
       └── feature/* or fix/*
```

Rules:

```text
main      stable/release branch
develop   integration branch
feature/* implementation work
fix/*     focused corrections
```

Create `develop` after the baseline commit:

```bash
git switch -c develop
git push -u github develop
git push gitlab develop
```

Create feature branches from `develop`:

```bash
git switch develop
git pull github develop
git switch -c feature/example
```

Merge completed work back with non-fast-forward merges:

```bash
git switch develop
git pull github develop
git merge --no-ff feature/example -m "merge: example feature"
git push github develop
git push gitlab develop
```

Do not perform normal implementation directly on `main`.

---

# 8. `.gitignore`

Create `.gitignore` in the repository root with the following complete content:

```gitignore
# ==========================================
# macOS
# ==========================================
.DS_Store

# ==========================================
# IDE / Editor
# ==========================================
.idea/
.vscode/
*.swp
*.swo

# ==========================================
# Environment / Secrets
# ==========================================
.env
.env.*
!.env.example

*.pem
*.key
*.p12
*.pfx

# Never commit local kubeconfig files
kubeconfig
kubeconfig-*
.kube/

# ==========================================
# Terraform
# ==========================================
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example

terraform.tfplan
*.tfplan

crash.log
crash.*.log

override.tf
override.tf.json
*_override.tf
*_override.tf.json

# .terraform.lock.hcl SHOULD be committed

# ==========================================
# Ansible
# ==========================================
*.retry

# ==========================================
# Python
# ==========================================
__pycache__/
*.py[cod]
.venv/
venv/

# ==========================================
# Logs / Temporary files
# ==========================================
*.log
tmp/
temp/
```

Important behavior:

```text
terraform/.terraform/          ignored
terraform/terraform.tfstate    ignored
terraform/terraform.tfvars     ignored
terraform/.terraform.lock.hcl  committed
terraform.tfvars.example       committed
```

---

# 9. Terraform Configuration

Create the Terraform feature branch:

```bash
git switch develop
git switch -c feature/terraform-eks
```

## 9.1 `terraform/versions.tf`

```hcl
terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59, < 7.0"
    }
  }
}
```

## 9.2 `terraform/providers.tf`

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

## 9.3 `terraform/variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region used for the project"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "automate-kubernetes-deployment"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Amazon EKS cluster name"
  type        = string
  default     = "ansible-capstone-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for Amazon EKS"
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "cluster_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS Kubernetes API endpoint"
  type        = list(string)
}
```

## 9.4 `terraform/locals.tf`

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )
}
```

## 9.5 `terraform/vpc.tf`

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs = local.availability_zones

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  enable_dns_support   = true
  enable_dns_hostnames = true

  map_public_ip_on_launch = true

  # Cost-aware capstone configuration:
  # no NAT Gateway is required for this public-subnet lab architecture.
  enable_nat_gateway = false
  enable_vpn_gateway = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = local.common_tags
}
```

## 9.6 `terraform/eks.tf`

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # kubectl and Ansible connect from the local control machine.
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.cluster_public_access_cidrs

  # Give the identity creating the cluster administrator access
  # through the EKS access-entry mechanism.
  enable_cluster_creator_admin_permissions = true

  # Keep the capstone focused and cost-aware.
  # EKS already encrypts Kubernetes secrets at rest using AWS-managed
  # encryption when no custom KMS encryption configuration is supplied.
  encryption_config = null
  create_kms_key    = false

  # Control-plane logging is not required by this capstone.
  enabled_log_types           = []
  create_cloudwatch_log_group = false

  # IRSA is not required by the application deployed in this capstone.
  enable_irsa = false

  addons = {
    coredns = {}

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.public_subnets

  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    application = {
      # Keep resource names short enough for generated AWS IAM
      # role and launch-template name prefixes.
      name = "app-nodes"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  tags = local.common_tags
}
```

## 9.7 `terraform/outputs.tf`

```hcl
output "aws_region" {
  description = "AWS region used by the project"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Amazon EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Amazon EKS Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "VPC created for the EKS cluster"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the project"
  value       = module.vpc.public_subnets
}

output "configure_kubectl" {
  description = "Command used to create/update the local kubeconfig entry"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
```

## 9.8 `terraform/terraform.tfvars.example`

```hcl
aws_region         = "ca-central-1"
project_name       = "automate-kubernetes-deployment"
environment        = "dev"
cluster_name       = "ansible-capstone-eks"
kubernetes_version = "1.36"

node_instance_types = [
  "t3.small"
]

# Replace this example address with your current public IP address using /32.
cluster_public_access_cidrs = [
  "203.0.113.10/32"
]
```

---

# 10. Terraform Initialization and Local Validation

From the project root:

```bash
cd terraform
terraform fmt -recursive
terraform fmt -check -recursive
terraform init
terraform validate
terraform providers
```

Expected validation result:

```text
Success! The configuration is valid.
```

`terraform init` creates:

```text
terraform/.terraform/
terraform/.terraform.lock.hcl
```

The `.terraform/` directory stays ignored. Commit `.terraform.lock.hcl`.

---

# 11. Configure the Operator Public IP

Do not leave the public Kubernetes API open to `0.0.0.0/0`.

Get the current public IPv4 address:

```bash
MY_IP="$(curl -4 -s https://checkip.amazonaws.com | tr -d '\n')"
echo "$MY_IP"
```

Create the real ignored `terraform/terraform.tfvars`:

```bash
cat > terraform.tfvars <<EOF2
cluster_public_access_cidrs = [
  "${MY_IP}/32"
]
EOF2
```

Verify that Git ignores it:

```bash
cd ..
git check-ignore -v terraform/terraform.tfvars
cd terraform
```

---

# 12. Terraform Pre-Provisioning Checks

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

Verify configured region:

```bash
aws configure get region
```

Expected project region:

```text
ca-central-1
```

Verify Kubernetes 1.36 is available before hard-coding it for a new deployment:

```bash
aws eks describe-cluster-versions \
  --region ca-central-1 \
  --cluster-versions 1.36 \
  --output table
```

If 1.36 is no longer supported when recreating this project, update `kubernetes_version` to a currently supported EKS version and ensure the local `kubectl` version is compatible.

Verify `t3.small` is offered:

```bash
aws ec2 describe-instance-type-offerings \
  --location-type region \
  --filters Name=instance-type,Values=t3.small \
  --region ca-central-1 \
  --query 'InstanceTypeOfferings[].InstanceType' \
  --output text
```

Verify at least two Availability Zones are available:

```bash
aws ec2 describe-availability-zones \
  --region ca-central-1 \
  --filters Name=state,Values=available \
  --query 'AvailabilityZones[].ZoneName' \
  --output table
```

Optionally inspect relevant service quotas:

```bash
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region ca-central-1 \
  --query 'Quota.{Name:QuotaName,Value:Value,Unit:Unit}' \
  --output table
```

Check that the cluster does not already exist:

```bash
aws eks describe-cluster \
  --region ca-central-1 \
  --name ansible-capstone-eks
```

Before the first deployment, `ResourceNotFoundException` is expected.

---

# 13. Terraform Plan

Generate a saved plan:

```bash
cd terraform
terraform plan -out=tfplan
```

The verified final configuration produced:

```text
Plan: 44 to add, 0 to change, 0 to destroy.
```

Inspect unwanted chargeable resources:

```bash
terraform show -no-color tfplan | \
grep -E 'aws_nat_gateway|aws_lb|aws_kms_key|aws_kms_alias|aws_cloudwatch_log_group|aws_iam_openid_connect_provider' \
|| echo "No NAT Gateway, Load Balancer, custom KMS key, CloudWatch log group, or IRSA OIDC provider planned."
```

Inspect the managed-node naming:

```bash
terraform show -no-color tfplan | \
grep -E 'app-nodes|eks-node-group' | head -20
```

Before applying a saved plan, make sure the public IP has not changed:

```bash
CURRENT_IP="$(curl -4 -s https://checkip.amazonaws.com | tr -d '\n')"
echo "$CURRENT_IP"
grep "${CURRENT_IP}/32" terraform.tfvars
```

If the IP changed, update `terraform.tfvars` and regenerate the plan.

---

# 14. Troubleshooting — Terraform IAM Role Name Prefix

## Symptom

The first plan failed with:

```text
Error: expected length of name_prefix to be in the range (1 - 38)
```

The generated prefix was:

```text
ansible-capstone-eks-nodes-eks-node-group-
```

## Cause

The original managed-node-group name was long. The EKS Terraform module appended its own suffix to build IAM resource names, pushing the IAM role prefix beyond the AWS provider limit.

## Fix

Use a shorter node-group name:

```hcl
name = "app-nodes"
```

The generated IAM prefix then becomes:

```text
app-nodes-eks-node-group-
```

## Verification

The corrected plan completed successfully:

```text
Plan: 44 to add, 0 to change, 0 to destroy.
```

This error was caught before `terraform apply`, so no paid infrastructure was created during troubleshooting.

---

# 15. Commit the Terraform Implementation

After successful local validation:

```bash
git add terraform/
git commit -m "feat: prepare Terraform EKS infrastructure"
git push -u github feature/terraform-eks
git push gitlab feature/terraform-eks
```

Merge into `develop`:

```bash
git switch develop
git pull github develop
git merge --no-ff feature/terraform-eks \
  -m "merge: Terraform EKS infrastructure"
git push github develop
git push gitlab develop
```

Any Terraform preflight corrections should be made on a dedicated fix branch, validated, and merged back to `develop` using the same `--no-ff` pattern.

---

# 16. Ansible/Kubernetes Configuration

Create the feature branch:

```bash
git switch develop
git switch -c feature/ansible-kubernetes
```

## 16.1 `ansible/requirements.yml`

```yaml
---
collections:
  - name: kubernetes.core
    version: "6.5.0"
```

Install on a fresh machine:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

## 16.2 `ansible/manifests/nginx-app.yaml`

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:stable-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

## 16.3 `ansible/deploy-to-kubernetes.yaml`

```yaml
---
- name: Deploy application to Kubernetes
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    ansible_python_interpreter: "{{ ansible_playbook_python }}"
    app_namespace: my-app

  tasks:
    - name: Create application namespace
      kubernetes.core.k8s:
        api_version: v1
        kind: Namespace
        name: "{{ app_namespace }}"
        state: present

    - name: Deploy Nginx application
      kubernetes.core.k8s:
        state: present
        namespace: "{{ app_namespace }}"
        src: "{{ playbook_dir }}/manifests/nginx-app.yaml"
```

No Ansible inventory, SSH private key, EC2 dynamic inventory, or remote Docker-install playbook is required because Ansible runs locally and communicates directly with the Kubernetes API through kubeconfig.

---

# 17. Validate Ansible Locally

Check the collection:

```bash
ansible-galaxy collection list kubernetes.core
```

Verify the module:

```bash
ansible-doc kubernetes.core.k8s >/dev/null \
  && echo "kubernetes.core.k8s module: AVAILABLE"
```

Inspect Ansible's runtime Python:

```bash
ANSIBLE_PLAYBOOK_PY="$(head -1 "$(command -v ansible-playbook)" | sed 's/^#!//')"
echo "$ANSIBLE_PLAYBOOK_PY"
"$ANSIBLE_PLAYBOOK_PY" --version
```

Verify required libraries inside that exact Python environment:

```bash
"$ANSIBLE_PLAYBOOK_PY" - <<'PY'
import kubernetes
import yaml
import jsonpatch

print("kubernetes:", kubernetes.__version__)
print("yaml: OK")
print("jsonpatch: OK")
PY
```

Validate YAML files:

```bash
"$ANSIBLE_PLAYBOOK_PY" - <<'PY'
from pathlib import Path
import yaml

for path in [
    Path("ansible/requirements.yml"),
    Path("ansible/deploy-to-kubernetes.yaml"),
    Path("ansible/manifests/nginx-app.yaml"),
]:
    with path.open() as f:
        docs = list(yaml.safe_load_all(f))
    print(f"{path}: VALID YAML ({len(docs)} document(s))")
PY
```

Run syntax validation:

```bash
ansible-playbook \
  -i localhost, \
  --syntax-check \
  ansible/deploy-to-kubernetes.yaml
```

Expected:

```text
playbook: ansible/deploy-to-kubernetes.yaml
```

Do not run the live playbook before EKS exists.

---

# 18. Commit the Ansible Implementation

```bash
git add ansible/
git commit -m "feat: add Ansible Kubernetes deployment"
git push -u github feature/ansible-kubernetes
git push gitlab feature/ansible-kubernetes
```

Merge into `develop` after validation:

```bash
git switch develop
git pull github develop
git merge --no-ff feature/ansible-kubernetes \
  -m "merge: Ansible Kubernetes deployment"
git push github develop
git push gitlab develop
```

---

# 19. Provision the EKS Infrastructure

Immediately before apply, confirm the public IP still matches `terraform.tfvars`:

```bash
cd terraform
CURRENT_IP="$(curl -4 -s https://checkip.amazonaws.com | tr -d '\n')"
grep "${CURRENT_IP}/32" terraform.tfvars
```

Generate a fresh saved plan if necessary:

```bash
terraform plan -out=tfplan
```

Apply exactly that reviewed plan:

```bash
terraform apply "tfplan"
```

Verified result:

```text
Apply complete! Resources: 44 added, 0 changed, 0 destroyed.
```

Inspect outputs:

```bash
terraform output
```

Verified project outputs included:

```text
aws_region = "ca-central-1"
cluster_name = "ansible-capstone-eks"
configure_kubectl = "aws eks update-kubeconfig --region ca-central-1 --name ansible-capstone-eks"
```

The VPC, subnet IDs, and EKS endpoint are generated at runtime and should not be hard-coded into the repository.

Remove the disposable plan after apply:

```bash
rm -f tfplan
```

Do not delete `terraform.tfstate` while the infrastructure still exists. Terraform needs the state for cleanup.

---

# 20. Verify EKS

Check the cluster:

```bash
aws eks describe-cluster \
  --region ca-central-1 \
  --name ansible-capstone-eks \
  --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}' \
  --output table
```

Verified:

```text
Name:    ansible-capstone-eks
Status:  ACTIVE
Version: 1.36
```

List the node group:

```bash
aws eks list-nodegroups \
  --region ca-central-1 \
  --cluster-name ansible-capstone-eks
```

Capture the generated node-group name:

```bash
NODEGROUP_NAME="$(
  aws eks list-nodegroups \
    --region ca-central-1 \
    --cluster-name ansible-capstone-eks \
    --query 'nodegroups[0]' \
    --output text
)"

echo "$NODEGROUP_NAME"
```

Inspect it:

```bash
aws eks describe-nodegroup \
  --region ca-central-1 \
  --cluster-name ansible-capstone-eks \
  --nodegroup-name "$NODEGROUP_NAME" \
  --query 'nodegroup.{Name:nodegroupName,Status:status,Version:version,Desired:scalingConfig.desiredSize,Min:scalingConfig.minSize,Max:scalingConfig.maxSize}' \
  --output table
```

Verified:

```text
Status:  ACTIVE
Version: 1.36
Desired: 1
Min:     1
Max:     2
```

---

# 21. Configure kubeconfig

Run:

```bash
aws eks update-kubeconfig \
  --region ca-central-1 \
  --name ansible-capstone-eks
```

Explicitly expose kubeconfig for the current shell:

```bash
export KUBECONFIG="$HOME/.kube/config"
```

Verify the context:

```bash
kubectl config current-context
```

Verify connectivity:

```bash
kubectl cluster-info
kubectl get nodes -o wide
```

The worker node should be:

```text
Ready
```

Verify system workloads:

```bash
kubectl get pods -n kube-system -o wide
```

Expected healthy workloads include:

```text
aws-node
coredns
kube-proxy
```

Verify EKS addons:

```bash
aws eks list-addons \
  --region ca-central-1 \
  --cluster-name ansible-capstone-eks
```

Verified addons:

```text
coredns
kube-proxy
vpc-cni
```

---

# 22. Deploy the Application with Ansible

Before the first deployment, confirm the target namespace does not exist:

```bash
kubectl get namespace my-app
```

Before the first run, `NotFound` is expected.

Execute the playbook:

```bash
ansible-playbook \
  -i localhost, \
  ansible/deploy-to-kubernetes.yaml
```

Verified first successful recap:

```text
localhost : ok=2 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The first task creates the namespace. The second applies the Nginx Deployment and Service.

---

# 23. Troubleshooting — Ansible Wrong Python Interpreter

## Symptom

The first live Ansible attempt failed before creating any Kubernetes objects:

```text
Failed to import the required Python library (kubernetes)
```

Ansible had discovered:

```text
/opt/homebrew/bin/python3.14
```

for localhost module execution.

## Investigation

The `ansible-playbook` executable itself used:

```text
/opt/homebrew/Cellar/ansible/14.3.1/libexec/bin/python
```

That Ansible-managed Python already contained:

```text
kubernetes 36.0.3
PyYAML 6.0.3
jsonpatch 1.33
```

But the automatically discovered localhost interpreter did not contain `kubernetes`.

Verification command:

```bash
/opt/homebrew/bin/python3.14 - <<'PY'
try:
    import kubernetes
    print("kubernetes:", kubernetes.__version__)
except Exception as exc:
    print("kubernetes import FAILED:", exc)
PY
```

The import failed.

## Correct Fix

Do not install duplicate packages blindly into another global Python installation.

Make localhost use the Python runtime that launched the playbook:

```yaml
vars:
  ansible_python_interpreter: "{{ ansible_playbook_python }}"
```

This is portable across Ansible/Homebrew updates and avoids hard-coding a Cellar version path.

## Verification

After the fix:

```text
TASK [Create application namespace]  changed
TASK [Deploy Nginx application]      changed
PLAY RECAP                           failed=0
```

The fix was committed as:

```text
fix: use Ansible runtime Python for Kubernetes modules
```

and merged back to `develop` with `--no-ff`.

---

# 24. Verify the Kubernetes Deployment

Check the namespace:

```bash
kubectl get namespace my-app
```

Expected:

```text
my-app   Active
```

Inspect all resources:

```bash
kubectl get all -n my-app
```

Verified state:

```text
2 Nginx pods             Running
nginx-service            ClusterIP
nginx Deployment         2/2 Ready
ReplicaSet               2 desired / 2 current / 2 ready
```

Wait for rollout:

```bash
kubectl rollout status \
  deployment/nginx \
  -n my-app \
  --timeout=120s
```

Verified:

```text
deployment "nginx" successfully rolled out
```

Inspect pods:

```bash
kubectl get pods -n my-app -o wide
```

Inspect Deployment and Service:

```bash
kubectl get deployment nginx -n my-app
kubectl get service nginx-service -n my-app
```

Expected:

```text
Deployment READY: 2/2
Service TYPE:     ClusterIP
```

Check service endpoints:

```bash
kubectl get endpointslices \
  -n my-app \
  -l kubernetes.io/service-name=nginx-service \
  -o wide
```

---

# 25. Verify Ansible Idempotence

Run the same playbook a second time:

```bash
ansible-playbook \
  -i localhost, \
  ansible/deploy-to-kubernetes.yaml
```

Verified second recap:

```text
localhost : ok=2 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

This proves the desired Kubernetes state is idempotent: after the resources exist in the expected state, Ansible does not make unnecessary changes.

---

# 26. Optional Application HTTP Test

The Service intentionally uses `ClusterIP`, so no AWS Load Balancer is created.

To test Nginx from the local machine, start a port forward:

```bash
kubectl port-forward \
  -n my-app \
  service/nginx-service \
  8080:80 \
  >/tmp/nginx-port-forward.log 2>&1 &

PF_PID=$!
sleep 3
cat /tmp/nginx-port-forward.log
```

Test the response:

```bash
curl -I http://127.0.0.1:8080
curl -s http://127.0.0.1:8080 | head -20
```

Expected response includes:

```text
HTTP/1.1 200 OK
Server: nginx
```

Stop the port-forward:

```bash
kill "$PF_PID"
wait "$PF_PID" 2>/dev/null || true
```

This verification does not require a cloud load balancer.

---

# 27. Final Live Evidence Commands

Before cleanup, capture:

```bash
echo "===== CLUSTER ====="
aws eks describe-cluster \
  --region ca-central-1 \
  --name ansible-capstone-eks \
  --query 'cluster.{Name:name,Status:status,Version:version}' \
  --output table

echo
echo "===== NODE ====="
kubectl get nodes -o wide

echo
echo "===== NAMESPACE ====="
kubectl get namespace my-app

echo
echo "===== APPLICATION ====="
kubectl get all -n my-app

echo
echo "===== ADDONS ====="
aws eks list-addons \
  --region ca-central-1 \
  --cluster-name ansible-capstone-eks
```

---

# 28. Destroy the Infrastructure

Do not leave EKS running after project verification.

From the Terraform directory:

```bash
cd terraform
```

Confirm Terraform still tracks resources:

```bash
terraform state list
```

Generate a destruction plan:

```bash
terraform plan -destroy -out=destroy.tfplan
```

The verified project produced:

```text
Plan: 0 to add, 0 to change, 44 to destroy.
```

Apply the destruction plan **once**:

```bash
terraform apply "destroy.tfplan"
```

Verified result:

```text
Apply complete! Resources: 0 added, 0 changed, 44 destroyed.
```

Remove the disposable plan:

```bash
rm -f destroy.tfplan
```

---

# 29. Troubleshooting — Saved Destroy Plan Is Stale

A saved Terraform plan is tied to the state snapshot from which it was created.

After the destruction plan had already been applied successfully and Terraform had destroyed all 44 resources, trying to run the same saved plan again returned:

```text
Error: Saved plan is stale
```

This is expected because the first successful apply changed the Terraform state.

Do not treat this as a failed cleanup when the previous command already reported:

```text
Apply complete! Resources: 0 added, 0 changed, 44 destroyed.
```

The correct response is to remove the stale plan and verify state/AWS cleanup.

---

# 30. Verify Cleanup

Terraform state should be empty:

```bash
echo "===== REMAINING TERRAFORM STATE ====="
terraform state list
```

Verified result: no resource addresses returned.

Verify EKS no longer exists:

```bash
aws eks describe-cluster \
  --region ca-central-1 \
  --name ansible-capstone-eks
```

Verified result:

```text
ResourceNotFoundException
```

Verify the project VPC is gone:

```bash
aws ec2 describe-vpcs \
  --region ca-central-1 \
  --filters Name=tag:Project,Values=automate-kubernetes-deployment \
  --query 'Vpcs[].{VpcId:VpcId,State:State}' \
  --output table
```

Verified result: no project VPC returned.

Verify no project EC2 worker remains running or stopped:

```bash
aws ec2 describe-instances \
  --region ca-central-1 \
  --filters \
    Name=tag:Project,Values=automate-kubernetes-deployment \
    Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}' \
  --output table
```

Verified result: no project instances returned.

Return to the repository root:

```bash
cd ..
git status
```

Expected:

```text
nothing to commit, working tree clean
```

---

# 31. Optional Local kubeconfig Cleanup

Destroying EKS does not automatically remove the local kubeconfig context.

Find the project context:

```bash
kubectl config get-contexts -o name | grep 'ansible-capstone-eks' || true
```

If present, remove it. With the default `aws eks update-kubeconfig` naming, the context/cluster/user are normally the cluster ARN:

```bash
EKS_CONTEXT="$(kubectl config get-contexts -o name | grep 'ansible-capstone-eks' | head -1)"

if [ -n "$EKS_CONTEXT" ]; then
  kubectl config delete-context "$EKS_CONTEXT" || true
  kubectl config delete-cluster "$EKS_CONTEXT" || true
  kubectl config delete-user "$EKS_CONTEXT" || true
fi
```

If `KUBECONFIG` was exported only for this shell, it may also be cleared:

```bash
unset KUBECONFIG
```

---

# 32. Final Verified Results

The completed project verified:

```text
Terraform formatting                       PASS
Terraform initialization                   PASS
Terraform validation                       PASS
Terraform pre-provision plan                PASS
AWS authentication                         PASS
EKS 1.36 cluster creation                  PASS
EKS cluster status ACTIVE                  PASS
Managed node group ACTIVE                  PASS
Worker node Ready                          PASS
CoreDNS Running                            PASS
VPC CNI Running                            PASS
kube-proxy Running                         PASS
kubeconfig configuration                   PASS
kubectl → EKS                              PASS
Ansible YAML validation                    PASS
kubernetes.core.k8s availability           PASS
Ansible namespace creation                 PASS
Ansible Nginx deployment                   PASS
Nginx Deployment 2/2 Available             PASS
Two Nginx Pods Running                     PASS
ClusterIP Service                          PASS
Ansible second run changed=0               PASS
Terraform destroy 44 resources             PASS
Terraform state empty after destroy        PASS
EKS absent after destroy                   PASS
Project VPC absent after destroy           PASS
Project EC2 workers absent after destroy   PASS
```

An HTTP `curl` test through `kubectl port-forward` is documented as an application-level verification step for a fresh recreation. The Kubernetes-level deployment and service verification above were captured successfully in the completed run.

---

# 33. Final Documentation Branch and Release

After implementation and cleanup are complete, create the documentation branch from the current `develop`:

```bash
git switch develop
git pull github develop
git switch -c feature/final-documentation
```

Replace `README.md` and `RUNBOOK.md` with the final verified documentation.

Validate documentation changes:

```bash
git diff --check
git status
```

Run a basic secret scan before committing:

```bash
git grep -nEI \
'(AKIA[0-9A-Z]{16}|aws_access_key_id|aws_secret_access_key|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)' \
-- . \
|| echo "No obvious AWS credentials or private keys found in tracked files."
```

Commit:

```bash
git add README.md RUNBOOK.md
git commit -m "docs: finalize project documentation"
```

Push the feature branch:

```bash
git push -u github feature/final-documentation
git push gitlab feature/final-documentation
```

Merge into `develop`:

```bash
git switch develop
git pull github develop
git merge --no-ff feature/final-documentation \
  -m "merge: final project documentation"
git push github develop
git push gitlab develop
```

Final release merge into `main`:

```bash
git switch main
git pull github main

git merge --no-ff develop \
  -m "release: complete automated Kubernetes deployment capstone"

git push github main
git push gitlab main
```

Verify:

```bash
git status
git log --oneline --graph --decorate --all -20
git branch -vv
```

Optional release tag:

```bash
git tag -a v1.0.0 -m "Automate Kubernetes Deployment capstone v1.0.0"
git push github v1.0.0
git push gitlab v1.0.0
```

---

# 34. Fresh Deployment Checklist

For a future clean deployment, the shortest complete sequence is:

```text
1. Clone repository.
2. Check prerequisites.
3. Configure AWS CLI authentication.
4. Verify AWS region and supported EKS version.
5. Install kubernetes.core from ansible/requirements.yml.
6. cd terraform.
7. Create ignored terraform.tfvars with current public IP /32.
8. terraform init.
9. terraform fmt -check -recursive.
10. terraform validate.
11. terraform plan -out=tfplan.
12. Review the plan.
13. terraform apply "tfplan".
14. aws eks update-kubeconfig.
15. export KUBECONFIG="$HOME/.kube/config".
16. kubectl get nodes and verify Ready.
17. Verify kube-system workloads.
18. Run ansible-playbook -i localhost, ansible/deploy-to-kubernetes.yaml from repo root.
19. Verify my-app namespace, Deployment, Pods, and Service.
20. Run Ansible again and confirm changed=0.
21. Optionally port-forward and curl Nginx.
22. Capture evidence.
23. terraform plan -destroy -out=destroy.tfplan.
24. Review destruction plan.
25. terraform apply "destroy.tfplan" exactly once.
26. Verify Terraform state is empty.
27. Verify EKS, VPC, and worker instances are gone.
28. Remove stale kubeconfig context if desired.
```

---

# 35. Final Notes

This project is intentionally small and focused. It demonstrates the required relationship between:

```text
Terraform
→ AWS EKS infrastructure
→ kubeconfig
→ Ansible
→ Kubernetes namespace and application deployment
```

without introducing unrelated infrastructure or CI/CD tooling.

For a production environment, additional controls would normally be considered, such as private worker subnets, controlled egress, remote Terraform state with locking, workload IAM, observability, policy enforcement, CI/CD, application ingress, TLS, and higher availability. Those are intentionally outside this capstone's required scope.
