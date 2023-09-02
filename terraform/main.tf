terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.65.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.3.2"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "random" {
}

#Resource Group
resource "azurerm_resource_group" "sql-rg" {
  name     = var.resource_group.name
  location = var.resource_group.location
}

#Storage Account
resource "azurerm_storage_account" "sql-storage-account" {
  name                     = var.sql-storage-account.name
  resource_group_name      = azurerm_resource_group.sql-rg.name
  location                 = azurerm_resource_group.sql-rg.location
  account_tier             = var.sql-storage-account.account_tier
  account_replication_type = var.sql-storage-account.account_replication_type
}

#Mysql Server
resource "azurerm_mssql_server" "sql-server" {
  name                         = var.sql-server.name
  resource_group_name          = azurerm_resource_group.sql-rg.name
  location                     = azurerm_resource_group.sql-rg.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = random_password.sql-password.result
}

#Mysql Database
resource "azurerm_mssql_database" "sql-Database" {
  name           = var.sql-Database.name
  server_id      = azurerm_mssql_server.sql-server.id
  collation      = var.sql-Database.collation
  license_type   = var.sql-Database.license_type
  max_size_gb    = 5
  read_scale     = false
  sku_name       = var.sql-Database.sku_name
  zone_redundant = false
}

#Service Plan
resource "azurerm_service_plan" "appservice" {
  name                = var.appservice.appservice_name
  resource_group_name = azurerm_resource_group.sql-rg.name
  location            = azurerm_resource_group.sql-rg.location
  sku_name            = var.appservice.sku_name
  os_type             = var.appservice.os_type
}

#Linux Web App
resource "azurerm_linux_web_app" "webapp175" {
  name                = var.webapp.webapp_name
  resource_group_name = azurerm_resource_group.sql-rg.name
  location            = azurerm_service_plan.appservice.location
  service_plan_id     = azurerm_service_plan.appservice.id
  site_config {
    use_32_bit_worker = var.webapp.use_32_bit_worker
    application_stack {
      dotnet_version = "6.0"
    }
  }
}

#Random password for sql server
resource "random_password" "sql-password" {
  length  = 12
  special = false
  numeric = true
  upper   = true
  lower   = true
}

#Virtual network
resource "azurerm_virtual_network" "sql-vnet" {
  name                = var.virtual_network.name
  address_space       = var.virtual_network.address_space
  location            = azurerm_resource_group.sql-rg.location
  resource_group_name = azurerm_resource_group.sql-rg.name
  depends_on          = [azurerm_resource_group.sql-rg]
}

#Subnet
resource "azurerm_subnet" "sql-subnet" {
  name                 = var.subnet.name
  resource_group_name  = azurerm_resource_group.sql-rg.name
  virtual_network_name = azurerm_virtual_network.sql-vnet.name
  address_prefixes     = var.subnet.address_prefixes
  depends_on           = [azurerm_virtual_network.sql-vnet]
}

#Network Security Group
resource "azurerm_network_security_group" "sql-nsg" {
  name                = var.network_security_group.network_security_group_name
  location            = azurerm_resource_group.sql-rg.location
  resource_group_name = azurerm_resource_group.sql-rg.name
  security_rule {
    name                       = var.security_rule.name
    priority                   = var.security_rule.priority
    direction                  = var.security_rule.direction
    access                     = var.security_rule.access
    protocol                   = var.security_rule.protocol
    source_port_range          = var.security_rule.source_port_range
    destination_port_range     = var.security_rule.destination_port_range
    source_address_prefix      = var.security_rule.source_address_prefix
    destination_address_prefix = var.security_rule.destination_address_prefix
  }
}

#Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "sql-nsg-asc" {
  subnet_id                 = azurerm_subnet.sql-subnet.id
  network_security_group_id = azurerm_network_security_group.sql-nsg.id
  depends_on                = [azurerm_network_security_group.sql-nsg]
}

#Public Ip Master
resource "azurerm_public_ip" "master-ip" {
  name                = var.public_ip.agent_ip_name
  resource_group_name = azurerm_resource_group.sql-rg.name
  location            = azurerm_resource_group.sql-rg.location
  allocation_method   = var.public_ip.allocation_method
  depends_on          = [azurerm_subnet.sql-subnet]
}

#Network Interface Master
resource "azurerm_network_interface" "master_nic" {
  name                = var.network_interface.master_nic_name
  location            = azurerm_resource_group.sql-rg.location
  resource_group_name = azurerm_resource_group.sql-rg.name

  ip_configuration {
    name                          = var.network_interface.ip_configuration_name
    subnet_id                     = azurerm_subnet.sql-subnet.id
    private_ip_address_allocation = var.network_interface.private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.master-ip.id
  }
  depends_on = [azurerm_public_ip.master-ip]
}

#Public Ip Agent
resource "azurerm_public_ip" "agentip" {
  name                = var.public_ip.master_ip_name
  resource_group_name = azurerm_resource_group.sql-rg.name
  location            = azurerm_resource_group.sql-rg.location
  allocation_method   = var.public_ip.allocation_method
}

#Network Interface Agent
resource "azurerm_network_interface" "agentnic" {
  name                = var.network_interface.agent_nic_name
  location            = azurerm_resource_group.sql-rg.location
  resource_group_name = azurerm_resource_group.sql-rg.name

  ip_configuration {
    name                          = var.network_interface.ip_configuration_name
    subnet_id                     = azurerm_subnet.sql-subnet.id
    private_ip_address_allocation = var.network_interface.private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.agentip.id
  }
}

#Linux Virtual Machine Master
resource "azurerm_linux_virtual_machine" "masterVm" {
  name                            = "master${random_string.masterVm.result}"
  resource_group_name             = azurerm_resource_group.sql-rg.name
  location                        = azurerm_resource_group.sql-rg.location
  size                            = var.virtual_machines.size
  priority                        = var.virtual_machines.priority
  eviction_policy                 = var.virtual_machines.eviction_policy
  max_bid_price                   = var.virtual_machines.max_bid_price
  admin_username                  = var.vm_secrets.admin_username
  admin_password                  = random_password.masterVm-password.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.master_nic.id,
  ]
  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }
  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }
}

#Virtual Machine Extension
resource "azurerm_virtual_machine_extension" "masterVm" {
  name                 = var.vm_extension.name
  virtual_machine_id   = azurerm_linux_virtual_machine.masterVm.id
  publisher            = var.vm_extension.publisher
  type                 = var.vm_extension.type
  type_handler_version = var.vm_extension.type_handler_version

  protected_settings = var.vm_extension.protected_settings
  depends_on         = [azurerm_linux_virtual_machine.masterVm]
}

#Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "agentVm2" {
  name                            = "agent${random_string.agentVm.result}"
  resource_group_name             = azurerm_resource_group.sql-rg.name
  location                        = azurerm_resource_group.sql-rg.location
  size                            = var.virtual_machines.agent_size
  priority                        = var.virtual_machines.priority
  eviction_policy                 = var.virtual_machines.eviction_policy
  max_bid_price                   = var.virtual_machines.max_bid_price
  admin_username                  = var.vm_secrets.admin_username
  admin_password                  = random_password.agentVm-password.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.agentnic.id,
  ]
  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }
  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }
  depends_on = [azurerm_public_ip.agentip]
}

#Virtual Machine Extension
resource "azurerm_virtual_machine_extension" "agentVm" {
  name                 = var.vm_extension.name
  virtual_machine_id   = azurerm_linux_virtual_machine.agentVm2.id
  publisher            = var.vm_extension.publisher
  type                 = var.vm_extension.type
  type_handler_version = var.vm_extension.type_handler_version

  protected_settings = var.vm_extension.protected_settings2
  depends_on         = [azurerm_linux_virtual_machine.agentVm2]
}

#Redis cache
resource "azurerm_redis_cache" "sql-redis" {
  name                = "rediscache${random_string.rediscache.result}"
  location            = azurerm_resource_group.sql-rg.location
  resource_group_name = azurerm_resource_group.sql-rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false

  redis_configuration {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "allkeys-lru"
  }
}

resource "azurerm_redis_firewall_rule" "sql-redis-firewall" {
  name                = "sqlredisfirewall"
  redis_cache_name    = azurerm_redis_cache.sql-redis.name
  resource_group_name = azurerm_resource_group.sql-rg.name
  start_ip            = "0.0.0.0"
  end_ip              = "0.0.0.0"
}

#Random string
resource "random_string" "masterVm" {
  length  = 4
  numeric = true
  upper   = false
  lower   = false
  special = false
}

#Random string
resource "random_string" "agentVm" {
  length  = 4
  numeric = true
  upper   = false
  lower   = false
  special = false
}

#Random string
resource "random_string" "rediscache" {
  length  = 6
  numeric = true
  upper   = false
  lower   = false
  special = false
}

#Random password for master vm
resource "random_password" "masterVm-password" {
  length  = 12
  special = false
  numeric = true
  upper   = true
  lower   = true
}

#Random password for agent vm
resource "random_password" "agentVm-password" {
  length  = 12
  special = false
  numeric = true
  upper   = true
  lower   = true
}