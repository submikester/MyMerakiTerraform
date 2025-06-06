variable "network_file" {
  description = "Relative path to the network file"
  default     = "fullnetworklist.txt"
}
locals {
  raw_lines = split("\n", trimspace(file(var.network_file)))
  networks = [
      for line in local.raw_lines : {
      name          = trimspace(split("|", line)[0])
      tags          = [for t in split(",", split("|", line)[1]) : trimspace(t)]
      time_zone     = trimspace(split("|", line)[2])
      product_types = [for pt in split(",", split("|", line)[3]) : trimspace(pt)]
    }
  ]
}
resource "meraki_network" "network" {
  for_each = {
    for net in local.networks : net.name => net
  }
  name            = each.value.name
  organization_id = 669910444571365562
  time_zone       = each.value.time_zone
  tags            = each.value.tags
  product_types   = each.value.product_types
}