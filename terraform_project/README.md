# Terraform Azure VM Provisioning

A simple Terraform project that deploys a small Azure Linux VM lab with secure SSH access, a public web VM, a private worker VM, cloud-init bootstrapping, tagging, and daily auto-shutdown.

## Architecture

```text
Remote User
    |
    | SSH 22 and HTTP 80 from specific public IP
    v
Static Public IP
    |
Public VM: beginner-linux-vm-01
    |  - Ubuntu
    |  - Nginx installed with cloud-init
    |  - Acts as SSH jump host
    |
Same VNet/Subnet: 10.10.1.0/24
    |
Private VM: beginner-linux-vm-02
       - Ubuntu
       - No public IP
       - Reachable through the public VM jump host
```

## Use Cases Covered

- Provision Azure infrastructure with Terraform.
- Deploy a secure public Linux VM using SSH key login only.
- Disable password authentication.
- Restrict SSH access to your own public IP CIDR.
- Bootstrap a VM with cloud-init and install Nginx.
- Deploy a second private VM in the same subnet.
- Access the private VM through the public VM as a jump host.
- Apply tags for cost tracking and cleanup.
- Configure daily auto-shutdown for both VMs.
- Practice Terraform state recovery with import if Azure and state drift.

## Resources Created

- Resource group
- Virtual network
- Subnet
- One static public IP
- Network security group
- NSG rule for SSH from your IP only
- NSG rule for HTTP from your IP only
- Public network interface
- Private network interface
- Public Ubuntu Linux VM
- Private Ubuntu Linux VM
- Auto-shutdown schedule for both VMs

## File Structure

```text
.
├── main.tf              # Azure resources
├── variables.tf         # Input variables and validation
├── outputs.tf           # Useful values after deployment
├── providers.tf         # AzureRM provider configuration
├── cloud-init.yaml      # Nginx bootstrap script for the public VM
├── terraform.tfvars     # Local variable values, not committed
└── README.md
```

## Prerequisites

- Azure CLI installed and logged in:

```powershell
az login
```

- Terraform installed:

```powershell
terraform version
```

- RSA SSH key pair for Azure Linux VM login:

```powershell
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f "$HOME\.ssh\id_rsa_azure_vm"
```

Azure Linux VMs reject `ed25519` keys for this resource, so use RSA.

## Configuration

Create a local `terraform.tfvars` file:

```hcl
subscription_id     = "00000000-0000-0000-0000-000000000000"
location            = "eastasia"
resource_group_name = "rg-beginner-linux-vm"

vm_size         = "Standard_D2s_v3"
private_vm_size = "Standard_D2s_v3"

admin_username      = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa_azure_vm.pub"

# Use your own current public IP with /32.
# Do not use 0.0.0.0/0.
my_public_ip_cidr = "203.0.113.10/32"

auto_shutdown_time     = "1900"
auto_shutdown_timezone = "UTC"

tags = {
  project     = "terraform-azure-vm-lab"
  environment = "lab"
  owner       = "your-name"
  ttl         = "destroy-after-lab"
}
```

Find your current public IP:

```powershell
(Invoke-RestMethod -Uri https://api.ipify.org) + "/32"
```

## Deploy

Initialize and check the configuration:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
```

Apply only when you are ready to create Azure resources:

```powershell
terraform apply
```

## Outputs

After deployment, Terraform prints:

- `public_ip_address`
- `ssh_command`
- `web_url`
- `private_vm_private_ip_address`
- `private_vm_ssh_via_jump_command`

Show outputs again:

```powershell
terraform output
```

## Verify

Open the Nginx page from your browser:

```text
http://<public-ip>
```

Or print the exact URL:

```powershell
terraform output web_url
```

SSH to the public VM:

```powershell
terraform output ssh_command
```

SSH to the private VM through the public VM jump host:

```powershell
terraform output private_vm_ssh_via_jump_command
```

The jump-host flow is:

```text
User -> public VM -> private VM
```

You do not need to copy your private SSH key to the public VM.

## Security Notes

- SSH password authentication is disabled.
- SSH is allowed only from `my_public_ip_cidr`.
- HTTP is allowed only from `my_public_ip_cidr`.
- The private VM has no public IP address.
- Only one public IP is created.
- No secrets are hard-coded.
- `terraform.tfvars`, state files, and plan files should not be committed.

## Cost Notes

This lab is designed to stay modest, but Azure resources can still cost money.

- Use small VM sizes where your subscription has quota.
- Both VMs use `Standard_LRS` OS disks.
- Both VMs have daily auto-shutdown enabled.
- Destroy the lab immediately after use.
- Check Cost Management after the lab; cost data can take several hours to appear.

Avoid adding these unless you are deliberately studying them:

- NAT Gateway
- Application Gateway
- Azure Firewall
- Azure Bastion
- Load Balancer
- Premium SSD or Ultra Disk
- Extra public IP addresses

## Cleanup

Destroy all resources when finished:

```powershell
terraform destroy
```

Then confirm in Azure Portal that the resource group is gone or empty.

## Useful Azure Portal Checks

After creation, inspect:

- Resource group overview
- VM sizes, status, disks, and auto-shutdown
- Public VM public IP
- Private VM has no public IP
- NICs attached to the same subnet
- NSG inbound rules for SSH and HTTP
- Tags on resources
- Cost Management filtered by resource group

## Screenshots To Keep

Good screenshots for GitHub or self-review:

- `terraform apply` complete output
- `terraform output`
- Azure resource group overview
- NSG inbound rules
- Public VM overview
- Private VM overview showing no public IP
- Nginx browser page
- SSH to private VM through jump host
- Auto-shutdown enabled
- `terraform destroy` complete output

Hide or blur subscription IDs, tenant IDs, account emails, and your exact home public IP before posting screenshots publicly.

## Troubleshooting

If Azure says a VM size is unavailable, choose another size or region where your subscription has quota.

If Terraform says a resource already exists, the Azure resource may exist but be missing from local Terraform state. Import it with `terraform import` only after confirming it is the correct resource.

If the Nginx page does not load, check:

```bash
cloud-init status --long
systemctl status nginx
```

If SSH stops working, confirm your current public IP still matches `my_public_ip_cidr`.
