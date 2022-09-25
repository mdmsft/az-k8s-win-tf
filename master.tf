locals {
  master_image_reference = split(":", var.master_image_reference)
}

resource "azurerm_ssh_public_key" "main" {
  name                = "ssh-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  public_key          = file(var.public_key_path)
}

resource "azurerm_network_interface" "main" {
  for_each                = var.masters
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

resource "azurerm_linux_virtual_machine" "main" {
  for_each                        = var.masters
  name                            = "vm-${local.resource_suffix}-${each.key}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  computer_name                   = each.key
  admin_username                  = var.master_admin_username
  disable_password_authentication = true
  size                            = var.master_size
  custom_data                     = base64encode(templatefile("${path.module}/cloud-config.yaml", {}))
  zone                            = index(tolist(var.masters), each.key) % 3 + 1

  network_interface_ids = [
    azurerm_network_interface.main[each.key].id
  ]

  admin_ssh_key {
    username   = var.master_admin_username
    public_key = azurerm_ssh_public_key.main.public_key
  }

  os_disk {
    name                 = "osdisk-${local.resource_suffix}-${each.key}"
    disk_size_gb         = 32
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.master_image_reference.0
    offer     = local.master_image_reference.1
    sku       = local.master_image_reference.2
    version   = local.master_image_reference.3
  }

  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }
}
