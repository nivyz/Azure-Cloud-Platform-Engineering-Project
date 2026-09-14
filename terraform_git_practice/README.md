# Multi-Environment Azure Infrastructure with Terraform

This project demonstrates a small, production-shaped Terraform workflow for Azure, executed via Github Actions. It uses reusable modules, isolated `dev`, `qa`, and `prod` state, GitHub Actions authentication and manually controlled plans and deployments.

The current version intentionally creates one resource group per environment. This keeps the first iteration inexpensive and makes Terraform, remote state, identity and automation easy to verify before adding networking or application services.

## Architecture

```text
GitHub Actions
     |
     | short-lived OIDC token (no client secret)
     v
Microsoft Entra application / service principal
     |
     +-- Contributor ----------------------> Azure resources
     `-- Storage Blob Data Contributor ----> Terraform state

Azure Storage container: tfstate
     |-- dev.tfstate
     |-- qa.tfstate
     `-- prod.tfstate
```

## Resources

Bootstrap manages:

- `rg-tfpractice-tfstate`
- An Azure Storage account with shared-key access disabled
- Private `tfstate` blob container with versioning

Environment roots manage:

- `rg-tfpractice-dev`
- `rg-tfpractice-qa`
- `rg-tfpractice-prod`

## Prerequisites

- Azure subscription and Azure CLI
- Terraform `1.14.x`
- Git and GitHub
- Permission to create resources and role assignments

Local authentication:

```powershell
az login
az account show --output table
$env:TF_VAR_subscription_id = (az account show --query id --output tsv).Trim()
```

## Bootstrap remote state

State storage must exist before environments can use it:

```powershell
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan
terraform -chdir=bootstrap apply
terraform -chdir=bootstrap output
```

Bootstrap state remains local and must be protected. Environment state is stored remotely in Azure.

## Run locally

Example for development:

```powershell
$env:TF_VAR_subscription_id = (az account show --query id --output tsv).Trim()
Push-Location environments/dev
terraform init -reconfigure '-backend-config=backend.hcl'
terraform fmt -check
terraform validate
terraform plan
Pop-Location
```

## GitHub Actions

The parent repository contains `.github/workflows/terraform-deploy.yml`. It is manually triggered with two inputs:

- Environment: `dev`, `qa`, or `prod`
- Operation: `plan` or `apply`

The workflow checks out the repository, signs into Azure through OIDC, installs Terraform, checks formatting, initializes remote state, validates, plans, and applies only when requested.

GitHub environments are named:

```text
dev
qa
prod
```

Required Actions secrets:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

No Azure client secret is stored. Each environment has an explicit Entra federated credential:

```text
repo:<repository path>:environment:<environment>
```

## Security and state decisions

- Each environment has an independent state key.
- State uses Microsoft Entra authentication rather than storage keys.
- GitHub uses short-lived OIDC tokens instead of a long-lived secret.
- Workflow permissions are limited to repository read and OIDC token issuance.
- Concurrency prevents two operations on the same environment at once.
- Production should require approval where the GitHub plan supports it.
- Real `.tfvars`, `.terraform/`, plans, and state are ignored by Git; lock files are committed.

## Cleanup

Destroy environment resources through Terraform so state remains accurate:

```powershell
terraform -chdir=environments/dev destroy
terraform -chdir=environments/qa destroy
terraform -chdir=environments/prod destroy
```

Destroy bootstrap resources last. Never remove state storage while environments still depend on it. Resource groups have no direct charge; the state storage account can incur a very small capacity and transaction charge.

## Status and next improvements

Completed:

- Reusable resource-group module
- Independent development, QA and production roots
- Azure Blob remote state
- GitHub Actions OIDC authentication
- Manual plan/apply workflow

Suggested next iterations:

1. Add reusable virtual-network, subnet, and NSG modules.
2. Add pull-request formatting, validation, and plan checks.
3. Separate plan and apply jobs so the approved plan is exactly what is applied.
4. Narrow the service principal from subscription-wide Contributor access.
5. Add budgets, policy checks, and security scanning.

