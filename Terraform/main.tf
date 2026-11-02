locals {
  name  = "github-terraform-lab"
  shape = "VM.Standard.E2.1.Micro"
}

data "oci_identity_availability_domains" "available" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "oracle_linux" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = local.shape
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_identity_compartment" "lab" {
  compartment_id = var.tenancy_ocid
  name           = local.name
  description    = "Laboratorio GitHub Actions y Terraform"
  enable_delete  = true
}

resource "oci_core_vcn" "lab" {
  compartment_id = oci_identity_compartment.lab.id
  cidr_blocks    = ["10.23.0.0/20"]
  display_name   = "${local.name}-vcn"
  dns_label      = "ghlab"
}

resource "oci_core_internet_gateway" "lab" {
  compartment_id = oci_identity_compartment.lab.id
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "${local.name}-igw"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.lab.id
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "${local.name}-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.lab.id
  }
}

resource "oci_core_security_list" "ssh" {
  compartment_id = oci_identity_compartment.lab.id
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "${local.name}-ssh"

  ingress_security_rules {
    protocol    = "6"
    source      = var.ssh_allowed_cidr
    source_type = "CIDR_BLOCK"
    description = "SSH desde el equipo del alumno"
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = oci_identity_compartment.lab.id
  vcn_id                     = oci_core_vcn.lab.id
  cidr_block                 = "10.23.11.0/24"
  display_name               = "${local.name}-public"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.ssh.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_instance" "vm" {
  compartment_id      = oci_identity_compartment.lab.id
  availability_domain = data.oci_identity_availability_domains.available.availability_domains[0].name
  display_name        = "${local.name}-vm"
  shape               = local.shape

  source_details {
    source_type             = "image"
    source_id               = try(data.oci_core_images.oracle_linux.images[0].id, null)
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = "labvm"
  }

  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]

    precondition {
      condition     = length(data.oci_core_images.oracle_linux.images) > 0
      error_message = "No se encontro una imagen Oracle Linux 8 compatible con VM.Standard.E2.1.Micro en Sao Paulo."
    }
  }
}
