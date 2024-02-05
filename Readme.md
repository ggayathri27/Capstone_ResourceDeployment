
# Create Azure Linux VM using Terraform

This Terraform configuration sets up a basic Azure infrastructure with a virtual network and subnets.

## Prerequisites

Before you begin, ensure you have the following:

- [Terraform](https://www.terraform.io/) installed (version >= 1.0.0)
- Azure subscription and authentication configured

## Configuration

1. Clone the repository:

   ```bash
   git clone <repository_url>

## Setup SSH Keys for Azure Linux VM

### Create Folder

```bash
cd terraform-manifests/
    mkdir ssh-keys
```

### Create SSH Key

```bash
    cd ssh-keys
    ssh-keygen \
        -m PEM \
        -t rsa \
        -b 4096 \
        -C "azureuser@myserver" \
        -f terraform-azure.pem 
```

Important Note: If you give passphrase during generation, during everytime you login to VM, you also need to provide passphrase.

### List Files

```bash
    ls -lrt ssh-keys/

    # Files Generated after above command 
    Public Key: terraform-azure.pem.pub -> Rename as terraform-azure.pub
    Private Key: terraform-azure.pem

    # Permissions for Pem file - Read Permisson 
    chmod 400 terraform-azure.pem
 ```

## Introduction

 Create the following Azure Resources \
        1. azurerm_public_ip \
        2. azurerm_network_interface \
        3. azurerm_network_security_group \
        4. azurerm_network_interface_security_group_association \
        5. Terraform Local Block for Security Rule Ports \
        6. Terraform for_each Meta-argument \
        7. azurerm_network_security_rule \
        8. Terraform Local Block for defining custom data to Azure Linux Virtual Machine \
        9. azurerm_linux_virtual_machine \
        10. Terraform Outputs for above listed Azured Resources \
        11. Terraform Functions

## Step 01: Create a Place holder file for Linux VM Input Variables

Create a file: c7-01-web-linuxvm-input-variables.tf

## Step 02: Create a Public IP Address

Create a file: c7-02-web-linuxvm-publicip.tf

### Create a IP Address

```hcl
    locals {
        resource_name_prefix = "webapp"
        }

        resource "azurerm_public_ip" "web_linuxvm_publicip" {
        name                = "${local.resource_name_prefix}-linuxvm-publicip"
        resource_group_name = azurerm_resource_group.rg.name
        location            = azurerm_resource_group.rg.location
        allocation_method   = "Static"
        sku = "Standard"
        #domain_name_label = "app1-vm-${random_string.myrandom.id}"
        }
```

## Step 03: Create a Network Interface

Create a file: c7-03-web-linuxvm-network-interface.tf

### Create a Network Interface

```hcl
    resource "azurerm_network_interface" "web_linuxvm_nic" {
    name                = "${local.resource_name_prefix}-web-linuxvm-nic"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "web-linuxvm-ip-1"
        subnet_id                     = azurerm_subnet.websubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.web_linuxvm_publicip.id 
    }
    }
```

## Step 04: Create Network Security Group and Associate to Linux VM Network Interface

Create a file: c7-04-web-linuxvm-network-security-group.tf

### Resource 1: Create Network Security Group (NSG)

```hcl
    resource "azurerm_network_security_group" "web_vmnic_nsg" {
    name                = "${azurerm_network_interface.web_linuxvm_nic.name}-nsg"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    }
```

### Resource 2: Associate NSG and Linux VM NIC

```hcl
    resource "azurerm_network_interface_security_group_association" "web_vmnic_nsg_associate" {
    depends_on = [ azurerm_network_security_rule.web_vmnic_nsg_rule_inbound]
    network_interface_id      = azurerm_network_interface.web_linuxvm_nic.id
    network_security_group_id = azurerm_network_security_group.web_vmnic_nsg.id
    }
```

### Resource 3: Create NSG Rules

#### Locals Block for Security Rules

```hcl
    locals {
    web_vmnic_inbound_ports_map = {
        "100" : "80", # If the key starts with a number, you must use the colon syntax ":" instead of "="
        "110" : "443",
        "120" : "22"
    } 
    }
```

#### NSG Inbound Rule for WebTier Subnets

```hcl
    resource "azurerm_network_security_rule" "web_vmnic_nsg_rule_inbound" {
    for_each = local.web_vmnic_inbound_ports_map
    name                        = "Rule-Port-${each.value}"
    priority                    = each.key
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = each.value 
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.web_vmnic_nsg.name
    }
```

## Step 05: Define Custom Data to Azure VM

Create a file: c7-05-web-linuxvm-resource.tf

- We have two options to define custom_data to Azure Linux VM
- Option 1: Using file as input (shell script file or cloud-init txt file)
- Option 2: Define the code in Terraform locals block
- We will review both options and choose option-2 for implementation.
- Commented code will be available in azurerm_linux_virtual_machine to use option-1 too.

### Locals Block for custom data

```hcl
    locals {
    webvm_custom_data = <<CUSTOM_DATA
    #!/bin/sh
    #!/bin/sh
    #sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl enable httpd
    sudo systemctl start httpd  
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
    sudo chmod -R 777 /var/www/html 
    sudo echo "Welcome to stacksimplify - WebVM App1 - VM Hostname: $(hostname)" > /var/www/html/index.html
    sudo mkdir /var/www/html/app1
    sudo echo "Welcome to stacksimplify - WebVM App1 - VM Hostname: $(hostname)" > /var/www/html/app1/hostname.html
    sudo echo "Welcome to stacksimplify - WebVM App1 - App Status Page" > /var/www/html/app1/status.html
    sudo echo '<!DOCTYPE html> <html> <body style="background-color:rgb(250, 210, 210);"> <h1>Welcome to Stack Simplify - WebVM APP-1 </h1> <p>Terraform Demo</p> <p>Application Version: V1</p> </body></html>' | sudo tee /var/www/html/app1/index.html
    sudo curl -H "Metadata:true" --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2020-09-01" -o /var/www/html/app1/metadata.html
    CUSTOM_DATA  
    }
```

### Resource: Azure Linux Virtual Machine

```hcl
    resource "azurerm_linux_virtual_machine" "web_linuxvm" {
    name = "${local.resource_name_prefix}-web-linuxvm"
    #computer_name = "web-linux-vm"  # Hostname of the VM (Optional)
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    size = "Standard_DS1_v2"
    admin_username = "azureuser"
    network_interface_ids = [ azurerm_network_interface.web_linuxvm_nic.id ]
    admin_ssh_key {
        username = "azureuser"
        public_key = file("${path.module}/ssh-keys/terraform-azure.pub")
    }
    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "RedHat"
        offer = "RHEL"
        sku = "83-gen2"
        version = "latest"
    }
    #custom_data = filebase64("${path.module}/app-scripts/redhat-webvm-script.sh")    
    custom_data = base64encode(local.webvm_custom_data)  

}
```

## Step 06: Terraform Outputs for Azure Virtual Machine Deployment

Create a file: c7-06-web-linuxvm-outputs.tf

### Public IP Outputs

#### Public IP Address

```hcl
    output "web_linuxvm_public_ip" {
    description = "Web Linux VM Public Address"
    value = azurerm_public_ip.web_linuxvm_publicip.ip_address
    }
```

### Network Interface Outputs

#### Network Interface ID

```hcl
    output "web_linuxvm_network_interface_id" {
    description = "Web Linux VM Network Interface ID"
    value = azurerm_network_interface.web_linuxvm_nic.id
    }
```

#### Network Interface Private IP Addresses

```hcl
    output "web_linuxvm_network_interface_private_ip_addresses" {
    description = "Web Linux VM Private IP Addresses"
    value = [azurerm_network_interface.web_linuxvm_nic.private_ip_addresses]
    }
```

### Linux VM Outputs

#### Virtual Machine Public IP

```hcl
    output "web_linuxvm_public_ip_address" {
    description = "Web Linux Virtual Machine Public IP"
    value = azurerm_linux_virtual_machine.web_linuxvm.public_ip_address
    }
```

#### Virtual Machine Private IP

```hcl
    output "web_linuxvm_private_ip_address" {
    description = "Web Linux Virtual Machine Private IP"
    value = azurerm_linux_virtual_machine.web_linuxvm.private_ip_address
    }
```

#### Virtual Machine 128-bit ID

```hcl
    output "web_linuxvm_virtual_machine_id_128bit" {
    description = "Web Linux Virtual Machine ID - 128-bit identifier"
    value = azurerm_linux_virtual_machine.web_linuxvm.virtual_machine_id
    }
```

#### Virtual Machine ID

```hcl
    output "web_linuxvm_virtual_machine_id" {
    description = "Web Linux Virtual Machine ID "
    value = azurerm_linux_virtual_machine.web_linuxvm.id
    }
```

## Step 07: Azure Infrastructure Configuration Variables

Create a file: terraform.tfvars \
Create a file: variables.tf

### terraform.tfvars

```hcl
        business_divsion = "hr"
        environment = "dev"
        resource_group_name = "rg"
        resource_group_location = "eastus"
        vnet_name = "vnet"
        vnet_address_space = ["10.1.0.0/16"]

        web_subnet_name = "websubnet"
        web_subnet_address = ["10.1.1.0/24"]

        app_subnet_name = "appsubnet"
        app_subnet_address = ["10.1.11.0/24"]

        db_subnet_name = "dbsubnet"
        db_subnet_address = ["10.1.21.0/24"]

        bastion_subnet_name = "bastionsubnet"
        bastion_subnet_address = ["10.1.100.0/24"]
```

### variables.tf

```hcl
    variable "business_division" {
    type    = string
    default = "hr"
    }

    variable "environment" {
    type    = string
    default = "dev"
    }

    variable "resource_group_name" {
    type    = string
    default = "rg"
    }

    variable "resource_group_location" {
    type    = string
    default = "eastus"
    }

    variable "vnet_name" {
    type    = string
    default = "vnet"
    }

    variable "vnet_address_space" {
    type    = list(string)
    default = ["10.1.0.0/16"]
    }

    variable "web_subnet_name" {
    type    = string
    default = "websubnet"
    }

    variable "web_subnet_address" {
    type    = list(string)
    default = ["10.1.1.0/24"]
    }

    variable "app_subnet_name" {
    type    = string
    default = "appsubnet"
    }

    variable "app_subnet_address" {
    type    = list(string)
    default = ["10.1.11.0/24"]
    }

    variable "db_subnet_name" {
    type    = string
    default = "dbsubnet"
    }

    variable "db_subnet_address" {
    type    = list(string)
    default = ["10.1.21.0/24"]
    }

    variable "bastion_subnet_name" {
    type    = string
    default = "bastionsubnet"
    }

    variable "bastion_subnet_address" {
    type    = list(string)
    default = ["10.1.100.0/24"]
    }
```

## Step 08: Execute Terraform Commands

### Intialize Terraform

```bash
terraform init 
```

### Validate Terraform Configuration

```bash
terraform validate
```

### Create a Terraform Plan

```bash
terraform plan
```

### Review and Apply

```bash
terraform apply -auto-approve
```

## Step 09: Verify Resources

### Virtual Network

1. Azure Resource Group
2. Azure Virtual Network
3. Azure Subnets (Web, App, DB, Bastion)
4. Azure Network Security Groups (Web, App, DB, Bastion)
5. View the topology
6. Verify Terraform Outputs in Terraform CLI

### Web Linux VM

1. Verify Public IP created for Web Linux VM
2. Verify Network Interface created for Web Linux VM
3. Verify Web Linux VM
4. Verify Network Security Groups associated with VM (web Subnet NSG and NIC NSG)
5. View Topology at Web Linux VM -> Networking
6. Connect to Web Linux VM

```bash
ssh -i ssh-keys/terraform-azure.pem azureuser@<Web-LinuxVM-PublicIP>
sudo su - 
cd /var/log
tail -100f cloud-init-output.log
cd /var/www/html
ls -lrt
cd /var/www/html/app1
ls -lrt
exit
exit
```

### Access Sample Application

- [http://&lt;PUBLIC-IP&gt;/](http://<PUBLIC-IP>/)
- [http://&lt;PUBLIC-IP&gt;/app1/index.html](http://<PUBLIC-IP>/app1/index.html)
- [http://&lt;PUBLIC-IP&gt;/app1/hostname.html](http://<PUBLIC-IP>/app1/hostname.html)
- [http://&lt;PUBLIC-IP&gt;/app1/status.html](http://<PUBLIC-IP>/app1/status.html)
- [http://&lt;PUBLIC-IP&gt;/app1/metadata.html](http://<PUBLIC-IP>/app1/metadata.html)

**Note:** Make sure to replace `<PUBLIC-IP>` with the actual public IP address used in your setup.

## Step-10: Comment NSG associated with VM

1. **Comment Code:**
   In the file `c7-04-web-linuxvm-network-security-group.tf`, comment the NSG associated with Web Linux VM NIC.

   ```hcl
   # Comment code in c7-04-web-linuxvm-network-security-group.tf
   # NSG associated with Web Linux VM NIC is commented

2. **Run Commands**

    ```bash
    # Terraform Validate
    terraform validate

    # Terraform Plan
    terraform plan

    # Terraform Apply
    terraform apply -auto-approve
    ```

3. **Verification**

    1. Verify Network Security Groups associated with VM (web Subnet NSG only).
    2. Access the application using the following URL: ```http://<PUBLIC-IP>/app1/metadata.html.```

**Note:** Make sure to replace `<PUBLIC-IP>` with the actual public IP address used in your setup.

## Step 11: Delete Resources

### Destroy Created Resources

```bash
terraform destroy
```

OR

```bash
terraform apply -destroy -auto-approve
```

### Clean-Up Files

```bash
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## Conclusion

Congratulations! You've successfully deployed an Azure Linux VM using Terraform. Here's a quick summary of what you've accomplished:

Infrastructure Setup: Established a basic Azure infrastructure with a virtual network, subnets, and associated resources.

SSH Key Configuration: Generated SSH keys for secure access to the Linux VM.

Terraform Deployment: Used Terraform to orchestrate the deployment of Azure resources.

## Documentation

- [Azure Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### Functions

- [file](https://developer.hashicorp.com/terraform/language/functions/file)

- [filebase64](https://developer.hashicorp.com/terraform/language/functions/filebase64)

- [base64encode](https://developer.hashicorp.com/terraform/language/functions/base64encode)
