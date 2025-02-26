terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

provider "esxi" {
  esxi_hostname = "192.168.1.3"
  esxi_hostport = "22"
  esxi_hostssl  = "443"
  esxi_username = "root"
  esxi_password = "Jelger@1998!"
}

locals {
  ssh_key  = file("~/.ssh/id_ed25519.pub")
  vm_names = ["webserver", "dbserver"]
}

resource "esxi_guest" "ubuntu_vms" {
  count       = length(local.vm_names)
  guest_name  = local.vm_names[count.index]
  disk_store  = "datastore1"
  numvcpus    = 1
  memsize     = 1024
  ovf_source  = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.ova"

  network_interfaces {
    virtual_network = "VM Network"
  }

  guestinfo = {
    "userdata"          = base64encode(templatefile("userdata.yaml", { ssh_key = local.ssh_key }))
    "userdata.encoding" = "base64"
  }
}

# Output IP's voor Ansible inventory
output "ansible_inventory" {
  value = <<EOT
[webservers]
webserver ansible_host=${esxi_guest.ubuntu_vms[0].ip_address} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519

[dbservers]
dbserver ansible_host=${esxi_guest.ubuntu_vms[1].ip_address} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOT
}
