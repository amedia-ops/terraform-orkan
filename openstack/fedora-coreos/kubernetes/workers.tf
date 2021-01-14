# Worker instances
resource "openstack_networking_port_v2" "worker-ports" {
  count      = var.worker_count
  name       = "${var.cluster_name}-worker-${count.index}"
  tags       = [var.cluster_name]
  network_id = var.network_id
  security_group_ids = [
    openstack_networking_secgroup_v2.mgmt.id,
  ]
}

resource "openstack_networking_port_v2" "worker-vrf-ports" {
  count      = var.worker_count
  name       = "${var.cluster_name}-worker-vrf-${count.index}"
  tags       = [var.cluster_name]
  network_id = var.vrf_networks[element(var.availability_zones, count.index)]
  security_group_ids = [
    "3a4a1481-cfb0-4718-85cb-9bd43026444d",
  ]
  allowed_address_pairs {
    ip_address = var.pod_cidr
  }
  allowed_address_pairs {
    ip_address = var.service_cidr
  }
}

resource "openstack_compute_servergroup_v2" "workers" {
  name     = "${var.cluster_name}-workers"
  policies = ["anti-affinity"]
}


resource "openstack_compute_instance_v2" "workers" {
  count             = var.worker_count
  name              = "${var.cluster_name}-worker-${count.index}"
  tags              = [var.cluster_name]
  flavor_name       = var.worker_type
  image_name        = var.os_worker_image
  user_data         = data.ct_config.worker-ignitions.*.rendered[count.index]
  availability_zone = element(var.availability_zones, count.index)
  network {
    port = element(openstack_networking_port_v2.worker-ports.*.id, count.index)
  }
  network {
    port = element(openstack_networking_port_v2.worker-vrf-ports.*.id, count.index)
  }
  scheduler_hints {
    group = openstack_compute_servergroup_v2.workers.id
  }
  lifecycle {
    ignore_changes = [user_data]
  }
}

# Worker Ignition config
data "ct_config" "worker-ignitions" {
  count    = var.worker_count
  content  = data.template_file.worker-configs.*.rendered[count.index]
  strict   = true
  snippets = var.worker_snippets
}

# Worker Container Linux config
data "template_file" "worker-configs" {
  count    = var.worker_count
  template = file("${path.module}/fcc/worker.yaml")

  vars = {
    kubeconfig             = indent(10, module.bootstrap.kubeconfig-kubelet)
    ssh_authorized_key     = var.ssh_authorized_key
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    cluster_domain_suffix  = var.cluster_domain_suffix

    availability_zone = element(var.availability_zones, count.index)
    hostname          = "${var.cluster_name}-worker-${count.index}"
    eth0_address      = openstack_networking_port_v2.worker-ports[count.index].all_fixed_ips[0]
    eth0_gateway      = cidrhost("${openstack_networking_port_v2.worker-ports[count.index].all_fixed_ips[0]}/24", 1)
    eth0_network      = cidrhost("${openstack_networking_port_v2.worker-ports[count.index].all_fixed_ips[0]}/24", 0)
    eth1_address      = openstack_networking_port_v2.worker-vrf-ports[count.index].all_fixed_ips[0]
    eth1_gateway      = cidrhost("${openstack_networking_port_v2.worker-vrf-ports[count.index].all_fixed_ips[0]}/26", 1)
    dns_zone          = var.dns_zone
    zincati_service   = cidrhost(var.service_cidr, 15)
  }
}
