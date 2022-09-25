locals {
  worker_image_reference = split(":", var.worker_image_reference)
}

resource "azurerm_network_interface" "worker" {
  for_each                = var.workers
  name                    = "nic-${local.resource_suffix}-${each.key}"
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  internal_dns_name_label = each.key

  ip_configuration {
    name                          = "default"
    primary                       = true
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "worker" {
  for_each                 = var.workers
  name                     = "vm-${local.resource_suffix}-${each.key}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  computer_name            = each.key
  admin_username           = var.worker_admin_username
  admin_password           = var.worker_admin_password
  size                     = var.worker_size
  enable_automatic_updates = true
  timezone                 = "W. Europe Standard Time"
  zone                     = index(tolist(var.workers), each.key) % 3 + 1

  network_interface_ids = [
    azurerm_network_interface.worker[each.key].id
  ]

  os_disk {
    name                 = "osdisk-${local.resource_suffix}-${each.key}"
    disk_size_gb         = 128
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.worker_image_reference.0
    offer     = local.worker_image_reference.1
    sku       = local.worker_image_reference.2
    version   = local.worker_image_reference.3
  }
}
