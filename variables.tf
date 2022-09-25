variable "project" {
  type    = string
  default = "contoso"
}

variable "location" {
  type = object({
    name = string
    code = string
  })
}
variable "environment" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "address_space" {
  type = string
}

variable "bastion_scale_units" {
  type = number
}

variable "masters" {
  type = set(string)
}

variable "workers" {
  type = set(string)
}

variable "master_admin_username" {
  type = string
}

variable "master_size" {
  type = string
}

variable "master_image_reference" {
  type = string
}

variable "worker_size" {
  type = string
}

variable "worker_image_reference" {
  type = string
}

variable "worker_admin_username" {
  type = string
}

variable "worker_admin_password" {
  type      = string
  sensitive = true
}

variable "public_key_path" {
  type = string
}

variable "dns_zone_id" {
  type = string
}
