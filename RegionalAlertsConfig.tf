variable "usaregionalalerts_file" {
  description = "Relative path to the network file"
  default     = "USARegionalSiteAlertsList.txt"
}
locals {
  raw_regionalalertlines = split("\n", trimspace(file(var.usaregionalalerts_file)))

  regionasitelalerts = [
      for line in local.raw_regionalalertlines : {
      networkname          = trimspace(split("|", line)[0])
      name          = trimspace(split("|", line)[1])
      url     = trimspace(split("|", line)[2])
    }
  ]
}
resource "meraki_network_webhook_http_server" "regionalalerts" {
  for_each = {
    for net in local.regionasitelalerts : net.name => net
  }

  network_id            = meraki_network.network[each.value.networkname].id
  name       = each.value.name
  url            = each.value.url
  payload_template_payload_template_id = "wpt_00002"
}