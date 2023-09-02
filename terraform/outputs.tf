#Agent vm ip address
output "ip_address_agentvm" {
  value = azurerm_public_ip.agentip.ip_address
}

#Master vm ip address
output "ip_address_mastervm" {
  value = azurerm_public_ip.master-ip.ip_address

}
