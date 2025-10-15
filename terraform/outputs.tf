output "resource_group_name" {
  description = "Nom du Resource Group"
  value       = azurerm_resource_group.main.name
}

output "vm_name" {
  description = "Nom de la VM"
  value       = azurerm_windows_virtual_machine.main.name
}

output "public_ip_address" {
  description = "Adresse IP publique"
  value       = azurerm_public_ip.main.ip_address
}

output "admin_username" {
  description = "Nom d'utilisateur admin"
  value       = var.admin_username
}

output "admin_password" {
  description = "Mot de passe admin (sensible)"
  value       = random_password.admin.result
  sensitive   = true
}

output "rdp_connection_string" {
  description = "Commande RDP"
  value       = "mstsc /v:${azurerm_public_ip.main.ip_address}"
}