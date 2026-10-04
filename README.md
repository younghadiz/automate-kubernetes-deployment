# Automate Kubernetes Deployment

A hands-on DevOps capstone that provisions an Amazon EKS cluster with Terraform and deploys an application into a dedicated Kubernetes namespace with Ansible.

## Project Requirements

The assignment requires:

1. Create an Amazon EKS cluster using Terraform.
2. Write an Ansible playbook that deploys an application into a new Kubernetes namespace.
3. Configure Kubernetes access so Ansible can communicate with the EKS cluster.

## What This Project Implements

- AWS VPC with two public subnets across two Availability Zones
- Amazon EKS 1.36 cluster
- One EKS managed node group using a `t3.small` worker
- EKS access entry granting the cluster-creating IAM identity administrator access
- CoreDNS, kube-proxy, and VPC CNI EKS addons
- Restricted public Kubernetes API access using the operator's current `/32` public IP
- Ansible deployment from the local control machine through kubeconfig
- Dedicated `my-app` Kubernetes namespace
- Nginx Deployment with two replicas
- Internal `ClusterIP` Service
- Idempotent Ansible execution
- Complete Terraform cleanup after verification

## Architecture

```text
Local macOS Control Machine
│
├── Terraform
│   │
│   └── AWS
│       ├── VPC 10.0.0.0/16
│       ├── Public Subnet 10.0.1.0/24
│       ├── Public Subnet 10.0.2.0/24
│       ├── Internet Gateway / public route
│       └── Amazon EKS 1.36
│           ├── Managed node group
│           │   └── 1 x t3.small worker
│           ├── CoreDNS
│           ├── kube-proxy
│           └── VPC CNI
│
├── AWS CLI
│   └── aws eks update-kubeconfig
│
├── kubectl
│   └── Kubernetes API verification
│
└── Ansible
    └── kubernetes.core.k8s
        ├── Namespace: my-app
        ├── Deployment: nginx (2 replicas)
        └── Service: nginx-service (ClusterIP)
```

## Repository Structure

```text
.
├── ansible/
│   ├── deploy-to-kubernetes.yaml
│   ├── requirements.yml
│   └── manifests/
│       └── nginx-app.yaml
├── terraform/
│   ├── .terraform.lock.hcl
│   ├── eks.tf
│   ├── locals.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   ├── versions.tf
│   └── vpc.tf
├── .gitignore
├── README.md
└── RUNBOOK.md
```

## Verified Environment

The completed implementation was verified with:

| Tool | Verified Version |
|---|---:|
| macOS | 26.2 arm64 |
| Git | 2.52.0 |
| Terraform | 1.15.6 |
| AWS CLI | 2.34.36 |
| kubectl | 1.37.0 |
| Ansible Core | 2.21.3 |
| Ansible package | 14.3.1 |
| `kubernetes.core` | 6.5.0 |
| Ansible Python | 3.14.7 |
| Kubernetes Python client | 36.0.3 |
| PyYAML | 6.0.3 |
| jsonpatch | 1.33 |

## Cost-Aware Design

The project deliberately avoids unnecessary chargeable services.

It uses:

- one EKS control plane
- one `t3.small` managed worker node
- public worker networking for this short-lived lab
- an internal `ClusterIP` service

It intentionally does **not** create:

- NAT Gateway
- AWS Load Balancer
- RDS
- ECR
- custom KMS key
- CloudWatch EKS control-plane log group
- IRSA/OIDC provider
- Jenkins or other CI/CD infrastructure

The project follows this lifecycle:

```text
prepare locally
→ validate locally
→ plan
→ provision
→ configure kubeconfig
→ deploy with Ansible
→ verify
→ destroy
→ verify cleanup
```

## Security Decisions

- EKS public API access is restricted to the operator's current public IPv4 address using `/32` CIDR rather than `0.0.0.0/0`.
- Terraform state, real `.tfvars`, kubeconfig files, private keys, and environment secrets are ignored by Git.
- EC2 Instance Metadata Service v2 is required by the managed-node launch template.
- No AWS credentials are stored in the repository.
- The cluster creator is granted EKS administrator access through an EKS access entry rather than relying only on legacy configuration.

## Verified Results

The project successfully demonstrated:

```text
Terraform apply                     44 resources created
EKS cluster                         ACTIVE
Kubernetes version                  1.36
Managed node group                  ACTIVE
Worker node                         Ready
CoreDNS                             Running
VPC CNI                             Running
kube-proxy                          Running
kubectl → EKS                       Working
Ansible first run                   ok=2 changed=2 failed=0
Namespace my-app                    Active
Nginx Deployment                    2/2 Available
Nginx Pods                          2/2 Running
nginx-service                       ClusterIP
Ansible second run                  ok=2 changed=0 failed=0
Terraform destroy                   44 resources destroyed
Terraform state after cleanup       Empty
EKS after cleanup                   ResourceNotFoundException
Project VPC after cleanup           Not found
Project EC2 instances after cleanup None running/stopped
```

The Kubernetes deployment and service were verified successfully. The full runbook also includes an optional `kubectl port-forward` + `curl` application-response test for fresh deployments.

## Key Troubleshooting Lessons

Two issues were discovered before and during the live deployment:

1. **Generated IAM role name exceeded AWS prefix limits.** The original managed-node-group name was too long once the Terraform EKS module appended its own suffix. The node-group name was shortened to `app-nodes` before provisioning.
2. **Ansible selected the wrong localhost Python interpreter.** `kubernetes.core.k8s` initially ran through a Homebrew Python without the Kubernetes client library. The playbook was fixed with `ansible_python_interpreter: "{{ ansible_playbook_python }}"`, reusing the Python environment that already contained Ansible's required Kubernetes dependencies.

Both fixes were validated before being merged into `develop`.

## Git Workflow

```text
main
└── develop
    ├── feature/terraform-eks
    ├── feature/ansible-kubernetes
    ├── fix/terraform-preflight
    ├── feature/ansible-python-interpreter
    └── feature/final-documentation
```

Feature/fix branches are merged into `develop` using `--no-ff`. After final validation and documentation, `develop` is merged into `main` using `--no-ff`.

GitHub is the primary remote and GitLab is maintained as a mirror.

## Deployment

For the complete fresh-machine, start-to-finish procedure — including prerequisites, every configuration file, Terraform validation, AWS checks, provisioning, kubeconfig, Ansible deployment, troubleshooting, verification, and cleanup — see:

**[RUNBOOK.md](RUNBOOK.md)**

## Important Note About Kubernetes Versions

This implementation was verified with Amazon EKS Kubernetes `1.36`. EKS-supported versions change over time. Before recreating the environment in the future, verify that the configured version is still offered in the selected AWS region and update `kubernetes_version` if necessary.

## Attribution

Training reference:

- TechWorld with Nana — DevOps Bootcamp, Module 15: Ansible

Implementation, Terraform configuration, Ansible/Kubernetes configuration, troubleshooting, Git workflow, validation, cost controls, and documentation:

- Gafari Oladele Salaudeen
