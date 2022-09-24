locals {
  resource_suffix        = "${var.project}-${var.environment}-${var.location.code}"
  global_resource_suffix = "${var.project}-${var.environment}"
}
