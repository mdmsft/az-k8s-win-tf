project = "k8s"
location = {
  name = "westeurope"
  code = "weu"
}
environment            = "dev"
address_space          = "192.168.255.0/24"
bastion_scale_units    = 8
masters                = ["alpha", "bravo", "charlie"]
workers                = ["delta", "echo", "foxtrot"]
master_admin_username  = "azure"
master_size            = "Standard_B2s"
master_image_reference = "Canonical:UbuntuServer:18_04-lts-gen2:latest"
public_key_path        = "~/.ssh/id_rsa.pub"
worker_size            = "Standard_B4ms"
worker_image_reference = "MicrosoftWindowsServer:WindowsServer:2022-Datacenter:latest"
worker_admin_username  = "Azure"
