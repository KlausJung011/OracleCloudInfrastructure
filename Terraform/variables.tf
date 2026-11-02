variable "tenancy_ocid" {
  description = "Tenancy y compartimento padre del laboratorio."
  type        = string
}

variable "ssh_public_key" {
  description = "Clave publica SSH para el usuario opc."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519) ", trimspace(var.ssh_public_key)))
    error_message = "Usa una clave publica SSH de una sola linea (ssh-rsa o ssh-ed25519)."
  }
}

variable "ssh_allowed_cidr" {
  description = "IPv4 publica del equipo cliente, con mascara /32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr)) && can(regex("/32$", var.ssh_allowed_cidr))
    error_message = "Indica una IPv4 publica con /32, por ejemplo 198.51.100.10/32."
  }
}
