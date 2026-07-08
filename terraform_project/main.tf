locals {
  name_prefix = "beginner-linux-vm"
  common_tags = merge(var.tags, {
    managed_by = "terraform"
  })
}

# Creates the resource group that contains every resource in this project.
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Creates a virtual network where the VM's subnet will live.
resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Creates one subnet for the VM network interface.
resource "azurerm_subnet" "vm" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Creates a static public IP address so you can SSH to the VM after deployment.
resource "azurerm_public_ip" "vm" {
  name                = "${local.name_prefix}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Creates a network security group that controls inbound and outbound traffic for the VM.
resource "azurerm_network_security_group" "vm" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Allows SSH only from your public IP CIDR. This intentionally does not allow 0.0.0.0/0.
resource "azurerm_network_security_rule" "ssh" {
  name                        = "Allow-SSH-From-My-IP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my_public_ip_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.vm.name
}

# Allows HTTP to the web VM only from your public IP CIDR for the cloud-init Nginx lab.
resource "azurerm_network_security_rule" "http" {
  name                        = "Allow-HTTP-From-My-IP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.my_public_ip_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.vm.name
}

# Creates the network interface that connects the VM to the subnet and public IP address.
resource "azurerm_network_interface" "vm" {
  name                = "${local.name_prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

# Creates a private-only network interface for the worker VM in the same subnet.
resource "azurerm_network_interface" "private_vm" {
  name                = "${local.name_prefix}-private-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Attaches the network security group to the VM network interface.
resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# Attaches the network security group to the private VM network interface.
resource "azurerm_network_interface_security_group_association" "private_vm" {
  network_interface_id      = azurerm_network_interface.private_vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# Creates a public Ubuntu Linux VM that uses SSH key login only, disables password authentication, and installs Nginx with cloud-init.
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.name_prefix}-01"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  custom_data         = base64encode(templatefile("${path.module}/cloud-init.yaml", { vm_name = "${local.name_prefix}-01" }))

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]
  tags                            = local.common_tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Creates a second Ubuntu Linux VM with no public IP for private networking and jump-host practice.
resource "azurerm_linux_virtual_machine" "private_vm" {
  name                = "${local.name_prefix}-02"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.private_vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.private_vm.id]
  tags                            = local.common_tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Automatically stops the public VM each day to reduce accidental lab costs.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone
  tags                  = local.common_tags

  notification_settings {
    enabled = false
  }
}

# Automatically stops the private VM each day to reduce accidental lab costs.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "private_vm" {
  virtual_machine_id    = azurerm_linux_virtual_machine.private_vm.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone
  tags                  = local.common_tags

  notification_settings {
    enabled = false
  }
}
