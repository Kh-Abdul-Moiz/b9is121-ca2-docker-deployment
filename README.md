# B9IS121 CA2 — Automated Deployment Of Container and Cloud Administration

This repository automates the deployment of a static HTML/CSS site (served by Nginx and Docker) on an AWS EC2 instance. It uses Terraform for infrastructure and Ansible for configuration management. It also uses a GitHub Actions pipeline that rebuilds and redeploys automatically on every push to `main`.

## Repository structure

```
.
├── terraform/                  # Part 1 — Infrastructure Setup
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── ansible/                     # Part 2 — Configuration Management
│   ├── ansible.cfg
│   ├── inventory.ini.example
│   └── playbook.yml
├── app/                         # Part 3 — Docker Container Deployment
│   ├── index.html
│   ├── style.css
│   └── Dockerfile
├── .github/workflows/
│   └── deploy.yml               # Part 4 — CI/CD Pipeline Integration
├── architecture-diagram.svg
└── README.md
```

## Automation flow, step by step

1. **Terraform (`terraform/`)** used for cloud infrastructure: it looks up the default AWS VPC and subnet. Then it finds the latest Ubuntu 22.04 AMI automatically. It creates a security group allowing SSH only from the developer's IP and HTTP on port 80, and then launches a `t2.micro` EC2 instance in `eu-west-1`. Running `terraform apply` is a one-off, manual step — infrastructure doesn't change on every code push, only the application does.

2. **Ansible (`ansible/playbook.yml`)** configures that server: it updates the package cache, installs Docker Engine and its dependencies, enables the Docker service so it survives a reboot, adds the `ubuntu` user to the `docker` group, then pulls the latest application image from Docker Hub and starts it as a container, replacing any previous container of the same name. Every task is idempotent — running the playbook again causes no harm, it just confirms the desired state.

3. **Docker (`app/`)** packages the application. `Dockerfile` starts from the official `nginx:alpine` image and copies in `index.html` and `style.css` — there's no application runtime, interpreter, or dependency installation involved, which keeps the image small and the attack surface minimal.

4. **GitHub Actions (`.github/workflows/deploy.yml`)** ties it together into a CI/CD loop. On every push to `main`:
   - **Task 1 (`build-and-push`)** checks out the code, builds the Docker image from `app/Dockerfile`, and pushes it to Docker Hub.
   - **Task 2 (`deploy`)** installs Ansible on GitHub's own Ubuntu runner, writes a dynamic inventory file pointing at the EC2 instance, and runs `playbook.yml` against it over SSH — pulling the newly-pushed image and restarting the container.

   The infrastructure (Terraform) is provisioned once, manually. Everything downstream of that — building, pushing, configuring, deploying — is what the pipeline automates on every commit.

## Prerequisites

- AWS account (Free Tier) with an IAM user access key
- An EC2 key pair created in `eu-west-1`
- Terraform, Ansible, Docker, and the AWS CLI installed locally
- A Docker Hub account and access token
- A GitHub repository with four Actions secrets configured (see below)

## Setup summary

```bash
# 1. Infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in key_name and my_ip
terraform init && terraform apply

# 2. Build and push the image once, manually
cd ../app
docker build -t <dockerhub-username>/b9is121-static-site:latest .
docker push <dockerhub-username>/b9is121-static-site:latest

# 3. Configure the server and deploy the container
cd ../ansible
cp inventory.ini.example inventory.ini   # fill in the EC2 IP
ansible-galaxy collection install community.docker
ansible-playbook -i inventory.ini playbook.yml

# 4. From here, every `git push` to main rebuilds and redeploys automatically,
#    once these four GitHub Actions secrets are set:
#    DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, EC2_HOST, EC2_SSH_KEY
```

## Tool rationale

- **Terraform over AWS CloudFormation** — cloud-agnostic (the same approach applies to Azure or GCP), more human-readable HCL syntax, larger open-source provider ecosystem.
- **GitHub Actions over Azure DevOps** — lives directly alongside the code in the same repository, generous free tier, large marketplace of pre-built actions (`docker/build-push-action`, `docker/login-action`) that kept the pipeline to two small jobs.
- **Ansible over manual configuration or shell scripts** — idempotent (safe to re-run), agentless (only needs SSH, no separate agent software to install), and human-readable, directly supporting the "reused artifacts give the same result" requirement in the marking scheme.
- **Nginx serving a static site over a Python/Flask app** — no application runtime or interpreter to patch or secure, a smaller resulting image, and a smaller attack surface — a deliberate architectural choice worth discussing given this is a Cybersecurity MSc module.

## Cleanup

```bash
cd terraform
terraform destroy
```

## Troubleshooting

- **Ansible can't connect** — check the security group allows SSH from your current IP, and that `my_ip` in `terraform.tfvars` is still accurate (it changes if your network changes).
- **Site not reachable on port 80** — run `docker ps` on the EC2 instance to confirm the container is running, and check the security group has an inbound rule for port 80.
- **GitHub Actions `deploy` job fails at the SSH step** — the `EC2_HOST` or `EC2_SSH_KEY` secret is likely out of date against the current Terraform output.
