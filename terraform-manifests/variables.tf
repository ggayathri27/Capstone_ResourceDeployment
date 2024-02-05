# variables.tf

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
