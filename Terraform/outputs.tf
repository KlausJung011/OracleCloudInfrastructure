output "compartment_id" {
  value = oci_identity_compartment.lab.id
}

output "instance_id" {
  value = oci_core_instance.vm.id
}

output "public_ip" {
  value = oci_core_instance.vm.public_ip
}

output "ssh_user" {
  value = "opc"
}
