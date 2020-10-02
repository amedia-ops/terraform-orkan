# Kubernetes assets (kubeconfig, manifests)
module "bootstrap" {
  source = "git::https://github.com/amedia-ops/terraform-bootstrap.git?ref=b068997"

  cluster_name          = var.cluster_name
  api_virtual_ip        = openstack_networking_port_v2.kube-apiserver-vip.all_fixed_ips[0]
  api_servers           = [format("%s.%s", var.cluster_name, var.dns_zone), var.dns_zone, var.api_server_san]
  ca_private_key        = var.ca_private_key
  ca_certificate        = var.ca_certificate
  etcd_servers          = data.template_file.controllernames.*.rendered
  etcd_ipaddresses      = data.template_file.etcd_ipaddresses.*.rendered
  asset_dir             = var.asset_dir
  networking            = var.networking
  network_mtu           = var.network_mtu
  pod_cidr              = var.pod_cidr
  service_cidr          = var.service_cidr
  oidc_client_id        = var.oidc_client_id
  cluster_domain_suffix = var.cluster_domain_suffix
  enable_reporting      = var.enable_reporting
  enable_aggregation    = var.enable_aggregation
}

data "template_file" "etcd_ipaddresses" {
  count    = var.controller_count
  template = openstack_networking_port_v2.controller-ports[count.index].all_fixed_ips[0]
}

data "template_file" "controllernames" {
  count    = var.controller_count
  template = "$${cluster_name}-controller-$${index}.$${dns_zone}"

  vars = {
    index        = count.index
    cluster_name = var.cluster_name
    dns_zone     = var.dns_zone
  }
}