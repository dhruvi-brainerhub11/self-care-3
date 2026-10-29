# Infrastructure and deployment

Terraform provisions an EC2 app server and a MySQL RDS instance in the AWS default VPC. Ansible installs Docker and deploys the checked-out release. The GitHub Actions workflow runs on a self-hosted runner and connects to EC2 over SSH.

## Prerequisites

- An AWS account with a default VPC and subnets in at least two Availability Zones.
- AWS credentials configured locally for Terraform.
- An existing EC2 key pair in the target region.
- Terraform, Ansible, and Python 3 available on the self-hosted Actions runner.
- The runner can SSH to EC2 and can build Docker images.

## Provision AWS resources

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`. Set the key pair name and restrict `ssh_ingress_cidr` to your public IP using `/32`. Set `TF_VAR_db_username` and `TF_VAR_db_password` in your shell; Terraform state contains the RDS password and must be protected.

```sh
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
terraform -chdir=terraform output
```

RDS is private by default and only accepts MySQL from the EC2 security group. For direct local development against RDS, temporarily set `db_publicly_accessible = true` and `developer_cidr` to your current public IP `/32`, then apply. Do not use a broad CIDR, and restore the private settings after local testing.

## Local Compose testing

Copy `.env.dev.example` to `.env.dev`, then set the RDS endpoint, database user, password, and name. Direct local DB access requires the temporary RDS settings above.

```sh
docker compose --env-file .env.dev up --build
```

Open `http://localhost:8080`. The backend is not published to the host; frontend API calls are proxied inside the Compose network.

## Self-hosted CI/CD

Add a GitHub Actions self-hosted runner with Terraform, Ansible, Python 3, and Docker installed. Create a GitHub Actions environment named `production` and add these secrets:

- `EC2_HOST`: the Terraform `ec2_public_ip` output.
- `EC2_SSH_KEY`: private key matching the Terraform EC2 key pair.
- `EC2_KNOWN_HOSTS`: verified SSH host key entry for the EC2 host.
- `DB_HOST`: the Terraform `rds_address` output.
- `DB_USER`, `DB_PASSWORD`, `DB_NAME`: production database credentials and name.
- `DB_PORT`: optional; defaults to `3306`.

Push to `main` or run the workflow manually. It packages the app without env files, generates a restricted temporary production env file from Actions secrets, and runs `ansible/deploy.yml` against EC2.

The app serves HTTP on port 80. Put a TLS-enabled load balancer or reverse proxy in front of it for HTTPS. The backend port is not exposed publicly. Terraform's RDS deletion protection is enabled by default; disable it deliberately before destroying production data.