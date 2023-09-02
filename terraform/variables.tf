#Here we define the variable name and type

#resource group
variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

#storage account
variable "sql-storage-account" {
  type = object({
    name                     = string
    account_replication_type = string
    account_tier             = string
  })
}

#Mysql Server
variable "sql-server" {
  type = object({
    name    = string
    version = string
  })
}

#Mysql Database
variable "sql-Database" {
  type = object({
    name         = string
    collation    = string
    license_type = string
    sku_name     = string
  })
}

#azure webapp
variable "webapp" {
  type = object({
    webapp_name       = string
    use_32_bit_worker = string
  })
}

#azure appservice
variable "appservice" {
  type = object({
    appservice_name = string
    os_type         = string
    sku_name        = string
  })
}

#virtual network
variable "virtual_network" {
  type = object({
    name = string
    address_space = list(
      string
    )
  })
}

#subnet
variable "subnet" {
  type = object({
    name             = string
    address_prefixes = list(string)
  })
}

#public ips
variable "public_ip" {
  type = object({
    master_ip_name    = string
    agent_ip_name     = string
    allocation_method = string
  })
}

#network interface
variable "network_interface" {
  type = object({
    master_nic_name               = string
    agent_nic_name                = string
    ip_configuration_name         = string
    private_ip_address_allocation = string
  })

}

#network security group
variable "network_security_group" {
  type = object({
    network_security_group_name = string
  })
}

#security rule
variable "security_rule" {
  type = object({
    name                       = string
    priority                   = string
    priority                   = string
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  })
}

#virtual machines
variable "virtual_machines" {
  type = object({
    master_name                     = string
    agent_name                      = string
    agent_size                      = string
    size                            = string
    priority                        = string
    eviction_policy                 = string
    max_bid_price                   = string
    disable_password_authentication = string
  })

}

#vms os disks
variable "os_disk" {
  type = object({
    caching              = string
    storage_account_type = string
  })

}

#vms images
variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

}

#vms secrets
variable "vm_secrets" {
  type = object({
    admin_username = string
    admin_password = string
  })
  sensitive = true
}

#vms extension
variable "vm_extension" {
  type = object({
    name                 = string
    publisher            = string
    type                 = string
    type_handler_version = string
    protected_settings   = string
    protected_settings2  = string
  })
}
