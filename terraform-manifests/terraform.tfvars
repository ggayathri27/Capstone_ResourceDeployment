# Configuration Variables for Azure Infrastructure

# Business division for organizational context
business_division = "hr"

# Environment designation (e.g., dev, test, prod)
environment = "dev"

# Azure Resource Group details
resource_group_name = "rg"
resource_group_location = "eastus"

# Virtual Network details
vnet_name = "vnet"
vnet_address_space = ["10.1.0.0/16"]

# Subnet configurations
web_subnet_name = "websubnet"
web_subnet_address = ["10.1.1.0/24"]

app_subnet_name = "appsubnet"
app_subnet_address = ["10.1.11.0/24"]

db_subnet_name = "dbsubnet"
db_subnet_address = ["10.1.21.0/24"]

bastion_subnet_name = "bastionsubnet"
bastion_subnet_address = ["10.1.100.0/24"]

# End of Configuration Variables
