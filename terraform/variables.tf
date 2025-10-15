variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "vmwindows"
}

variable "environment" {
  description = "Environnement (dev, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur"
  type        = string
  default     = "azureadmin"
}

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "os_version" {
  description = "Version Windows Server"
  type        = string
  default     = "2022-datacenter-azure-edition"
}