# Automate Kubernetes Deployment

Capstone Project 2 from the TechWorld with Nana DevOps Bootcamp.

This project demonstrates how Terraform and Ansible can be combined to provision an Amazon EKS Kubernetes environment and automate application deployment into a dedicated Kubernetes namespace.

## Project Objective

The capstone requires:

1. Create an Amazon EKS cluster using Terraform.
2. Write an Ansible playbook that deploys an application into a new Kubernetes namespace.
3. Configure Kubernetes access so Ansible can communicate with the EKS cluster.

## Technologies

- AWS
- Amazon EKS
- Terraform
- Ansible
- Kubernetes
- Python
- Linux / Unix shell
- AWS CLI
- kubectl
- Git

## Planned Architecture

```text
Local Development Machine
        |
        | Terraform
        v
AWS Infrastructure
        |
        +-- VPC / Networking
        |
        +-- Amazon EKS Cluster
        |
        +-- EKS Managed Node Group
                 |
                 v
         Kubernetes Worker Nodes

Local Development Machine
        |
        | AWS CLI
        | aws eks update-kubeconfig
        v
Kubernetes API
        ^
        |
        | Ansible
        |
        +-- Create Kubernetes namespace
        +-- Create application Deployment
        +-- Create Kubernetes Service
```

## Application

A lightweight Nginx workload will be used to demonstrate the Kubernetes deployment workflow.

The application itself is not the primary focus of this capstone. The focus is infrastructure provisioning and deployment automation using Terraform, EKS, Kubernetes, and Ansible.

## Repository Structure

```text
.
├── ansible/
│   └── manifests/
├── terraform/
├── .gitignore
├── README.md
└── RUNBOOK.md
```

The structure will evolve as the project is implemented.

## Implementation Workflow

The project follows a cost-aware implementation process:

```text
Requirements
    ↓
Repository Setup
    ↓
Local Tooling Validation
    ↓
Terraform Preparation
    ↓
Ansible / Kubernetes Preparation
    ↓
Local Validation
    ↓
AWS Security Preparation
    ↓
Provision EKS
    ↓
Configure Kubernetes Access
    ↓
Deploy with Ansible
    ↓
Verify
    ↓
Document
    ↓
Destroy Cloud Resources
```

AWS infrastructure will be provisioned only after everything that can reasonably be prepared and validated locally has been completed.

## Project Status

| Phase                            | Status      |
| -------------------------------- | ----------- |
| Requirements                     | Complete    |
| Repository Setup                 | In Progress |
| Local Tooling / Environment      | Not Started |
| Terraform EKS Preparation        | Not Started |
| Ansible / Kubernetes Preparation | Not Started |
| Local Validation                 | Not Started |
| AWS / Security Preparation       | Not Started |
| EKS Provisioning                 | Not Started |
| Kubernetes Access                | Not Started |
| Ansible Deployment               | Not Started |
| End-to-End Verification          | Not Started |
| Documentation / Evidence         | Not Started |
| GitHub Submission                | Not Started |
| Cleanup                          | Not Started |

## Training Reference

This project is based on concepts taught in:

**TechWorld with Nana — DevOps Bootcamp — Module 15: Configuration Management with Ansible**

Relevant training topics include:

- Ansible playbooks
- Ansible modules and collections
- Ansible variables
- Terraform and Ansible
- Deploying applications to Kubernetes with Ansible

The infrastructure, automation configuration, troubleshooting, implementation decisions, and documentation in this repository are being implemented independently as part of the capstone exercise.

## Cost Awareness

Amazon EKS and associated AWS resources may generate charges.

The project therefore follows this principle:

```text
Prepare locally
→ validate locally
→ provision
→ deploy
→ verify
→ capture evidence
→ destroy infrastructure
```

## Author

Gafari Oladele Salaudeen