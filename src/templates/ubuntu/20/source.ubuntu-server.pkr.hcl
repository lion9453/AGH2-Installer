locals {
  buildtime = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
}

source "vsphere-iso" "ubuntu-server" {

  // vCenter Server Endpoint Settings and Credentials
  vcenter_server      = var.vc--endpoint
  username            = var.vc--username
  password            = var.vc--password
  insecure_connection = var.vc--insecure_connection

  // vSphere Settings
  datacenter = var.vc--datacenter
  cluster    = var.vc--cluster
  datastore  = var.vc--datastore
  folder     = var.vc--folder

  // Virtual Machine Settings
  guest_os_type        = var.vm--os_type
  vm_name              = var.vm--name
  firmware             = var.vm--firmware
  CPUs                 = var.vm--cpu_sockets
  cpu_cores            = var.vm--cpu_cores
  CPU_hot_plug         = var.vm--cpu_hot_add
  RAM                  = var.vm--mem_size
  RAM_hot_plug         = var.vm--mem_hot_add
  cdrom_type           = var.vm--cdrom_type
  disk_controller_type = var.vm--disk_controller_type

  storage {
    disk_size             = var.vm--disk_size
    disk_thin_provisioned = var.vm--disk_thin_provisioned
  }

  network_adapters {
    network      = var.vc--network
    network_card = var.vm--network_card
  }

  vm_version           = var.vc--vm_version
  remove_cdrom         = var.vc--remove_cdrom
  tools_upgrade_policy = var.vc--tools_upgrade_policy
  notes                = "Built by HashiCorp Packer on ${local.buildtime}."

  // Removable Media Settings
  iso_checksum = "${var.vm--iso_hash}:${var.vm--iso_checksum}"
  iso_urls     = [var.vm--iso_urls]

  // Boot and Provisioning Settings
  http_port_min = var.vc--http_port_min
  http_port_max = var.vc--http_port_max
  http_content = {
    "/meta-data" = file("data/meta-data")
    "/user-data" = templatefile("data/ubuntu-server-cloud-init.pkrtpl.hcl", {
      username = var.auth--username
      password_encrypted = var.auth--password_encrypted
      os_language = var.vm--os_language
      os_keyboard = var.vm--os_keyboard
      os_timezone = var.vm--os_timezone
      ssh_key     = var.auth--ssh_key
    })
  }
  boot_order = var.vm--boot_order
  boot_wait  = var.vm--boot_wait
  boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]
  ip_wait_timeout  = var.vm--ip_wait_timeout
  shutdown_command = "echo '${var.auth--password}' | sudo -S -E shutdown -P now"
  shutdown_timeout = var.vm--shutdown_timeout

  // Communicator Settings and Credentials
  communicator           = "ssh"
  ssh_username           = var.auth--username
  ssh_password           = var.auth--password
  ssh_handshake_attempts = var.auth--ssh_handshake_attempts
  ssh_port               = var.auth--ssh_port
  ssh_timeout            = var.auth--ssh_timeout
}
