# Automate Kubernetes Deployment — Implementation Runbook

## Purpose

This runbook records the complete implementation of the **Automate Kubernetes Deployment** capstone project.

The goal is to make the project reproducible.

The project uses:

- Terraform
- AWS
- Amazon EKS
- Kubernetes
- Ansible
- Python
- Linux / Unix shell

---

# 1. Project Requirements

The assignment requires:

1. Create an EKS cluster using Terraform.
2. Write an Ansible playbook that deploys an application into a new Kubernetes namespace.
3. Configure Kubernetes access so Ansible can communicate with the EKS cluster.

The assignment does not require Jenkins, ECR, Nexus, Prometheus, Grafana, or a CI/CD pipeline.

Those technologies will therefore not be introduced unless a later project requirement justifies them.

---

# 2. Source Boundaries

Three layers are kept separate throughout this project.

## 2.1 TechWorld with Nana Training

Nana's Module 15 provides the underlying Ansible concepts and implementation techniques.

Relevant lessons include:

- Introduction to Playbooks
- Modules and Collections in Ansible
- Ansible Variables
- Terraform and Ansible
- Deploying Application in Kubernetes

## 2.2 Capstone Requirements

The capstone determines what must actually be implemented.

The project requirements take precedence over unrelated examples from earlier or later training lessons.

## 2.3 Independent Implementation

The Terraform configuration, Ansible project structure, Kubernetes definitions, troubleshooting, validation, documentation, and AWS deployment in this repository are implemented independently for this capstone.

---

# 3. Engineering Principles

## Requirement First

```text
Assignment requirements
→ relevant Nana training method
→ compatible implementation
→ optional improvements
```

## Cost Control

Chargeable cloud infrastructure should remain running for the shortest reasonable period.

Therefore:

```text
prepare
→ validate
→ provision
→ deploy
→ verify
→ document evidence
→ destroy
```

## Security

The repository must never contain:

- AWS access keys
- AWS secret access keys
- private SSH keys
- kubeconfig credentials
- Terraform state containing sensitive data
- unprotected secrets

---

# 4. Planned Architecture

```text
                    Terraform
                       |
                       v
              +----------------+
              |      AWS       |
              +----------------+
                       |
                       v
                  Amazon EKS
                       |
                Managed Nodes
                       |
                       v
                 Kubernetes
                       ^
                       |
              Kubernetes API
                       ^
                       |
                kubeconfig
                       ^
                       |
          +------------+------------+
          |                         |
       kubectl                    Ansible
                                    |
                                    +-- Namespace
                                    |
                                    +-- Deployment
                                    |
                                    +-- Service
```

---

# 5. Planned Repository Structure

```text
automate-kubernetes-deployment/
│
├── terraform/
│
├── ansible/
│   └── manifests/
│
├── .gitignore
├── README.md
└── RUNBOOK.md
```

This structure may evolve as implementation requirements become clearer.

---

# 6. Project Lifecycle

| Phase | Description                      | Status      |
| ----- | -------------------------------- | ----------- |
| 01    | Requirements                     | Complete    |
| 02    | Repository Setup                 | In Progress |
| 03    | Local Tooling / Environment      | Not Started |
| 04    | Terraform EKS Preparation        | Not Started |
| 05    | Ansible / Kubernetes Preparation | Not Started |
| 06    | Local Validation                 | Not Started |
| 07    | AWS / Security Preparation       | Not Started |
| 08    | Provision EKS with Terraform     | Not Started |
| 09    | Configure Kubernetes Access      | Not Started |
| 10    | Verify EKS Cluster               | Not Started |
| 11    | Deploy Application with Ansible  | Not Started |
| 12    | End-to-End Verification          | Not Started |
| 13    | Documentation / Evidence         | Not Started |
| 14    | GitHub Submission                | Not Started |
| 15    | Cleanup                          | Not Started |

---

# 7. Implementation Record

## Phase 01 — Requirements

Status:

```text
COMPLETE
```

Confirmed technologies:

```text
Terraform
AWS EKS
Kubernetes
Ansible
Python
Linux / Unix
```

Confirmed required workflow:

```text
Terraform
→ Amazon EKS
→ kubeconfig
→ Ansible
→ Kubernetes namespace
→ application deployment
```

Technologies intentionally excluded from the baseline implementation:

```text
Jenkins
Nexus
Amazon ECR
Prometheus
Grafana
Jenkins Shared Library
```

They are not required for this capstone.

---

## Phase 02 — Repository Setup

Status:

```text
IN PROGRESS
```

Project directory:

```text
~/Documents/tech-workspace/devops-capstone-projects/automate-kubernetes-deployment
```

Repository initialized with Git.

Initial directories:

```text
terraform/
ansible/
ansible/manifests/
```

Initial documentation:

```text
README.md
RUNBOOK.md
.gitignore
```

---

# 8. Troubleshooting Log

Problems encountered during implementation will be recorded here using:

```text
Problem
→ Cause
→ Investigation
→ Fix
→ Verification
→ Lesson learned
```

No implementation issues recorded yet.

---

# 9. Cleanup Plan

Before provisioning infrastructure, the cleanup process must already be understood.

Expected final cleanup command:

```bash
terraform destroy
```

Kubernetes workloads may also be removed explicitly before infrastructure destruction when useful for verification.

Never assume AWS resources have been deleted merely because the application is no longer reachable.

Resource deletion must be verified.

---

# 10. Final Verification

Before declaring the project complete, verify:

```text
Terraform creates EKS successfully
Kubernetes nodes become Ready
kubectl communicates with the cluster
Ansible communicates with Kubernetes
new namespace exists
application Deployment exists
application Pods are Running
Kubernetes Service exists
application is reachable where applicable
Terraform can destroy the infrastructure
Git repository contains no secrets
README accurately represents the project
RUNBOOK contains the verified implementation
```