variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "southindia"
}

variable "resource_group_name" {
  description = "URL Shortener Blue-Green resource group"
  type        = string
  default     = "rg-urlshortener-bg"
}

variable "vm_size" {
  description = "Size for both Blue and Green VMs"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Linux VM administrator"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "postgres_admin" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "urladmin"
}

variable "postgres_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "active_color" {
  description = "Backend receiving traffic"
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be blue or green."
  }
}

variable "blue_image" {
  description = "Docker Hub image for Blue v1"
  type        = string
  default     = "yuviiee/url-shortener-blue-green:blue-v1"
}

variable "green_image" {
  description = "Docker Hub image for Green v2"
  type        = string
  default     = "yuviiee/url-shortener-blue-green:green-v2"
}

