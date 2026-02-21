terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Use the cloud image (not ISO!)
resource "libvirt_volume" "base" {
  name   = "ubuntu-base.qcow2"
  pool   = "default"
  source = "/home/thanhtut/Downloads/ISO/ubuntu-24.04-server-cloudimg-amd64.img"  # Changed from .iso to .img
}

# Get your SSH key
data "local_file" "ssh_key" {
  filename = "/home/thanhtut/.ssh/id_rsa.pub"
}

# VM1
resource "libvirt_volume" "vm1_disk" {
  name           = "vm1-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.base.id
  size           = 40 * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "vm1_init" {
  name      = "vm1-cloudinit.iso"
  pool      = "default"
  user_data = <<EOF
#cloud-config
hostname: vm1
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${chomp(data.local_file.ssh_key.content)}
package_update: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
EOF
  network_config = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: false
    addresses:
      - ${var.vm1_ip}/24
    gateway4: 192.168.122.1
    nameservers:
      addresses:
        - 8.8.8.8
        - 1.1.1.1
EOF
}

resource "libvirt_domain" "vm1" {
  name   = "vm1"
  memory = 2048
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.vm1_init.id

  disk {
    volume_id = libvirt_volume.vm1_disk.id
  }

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# VM2 - similar to VM1
resource "libvirt_volume" "vm2_disk" {
  name           = "vm2-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.base.id
  size           = 40 * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "vm2_init" {
  name      = "vm2-cloudinit.iso"
  pool      = "default"
  user_data = <<EOF
#cloud-config
hostname: vm2
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${chomp(data.local_file.ssh_key.content)}
package_update: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
EOF
  network_config = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: false
    addresses:
      - ${var.vm2_ip}/24
    gateway4: 192.168.122.1
    nameservers:
      addresses:
        - 8.8.8.8
        - 1.1.1.1
EOF
}

resource "libvirt_domain" "vm2" {
  name   = "vm2"
  memory = 1024
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.vm2_init.id

  disk {
    volume_id = libvirt_volume.vm2_disk.id
  }

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
