variable "localalerts_file" {
  description = "Relative path to the network file"
  default     = "LocalSiteAlertsList.txt"
}
locals {
  raw_alertlines = split("\n", trimspace(file(var.localalerts_file)))

  localalerts = [
      for line in local.raw_alertlines : {
      networkname          = trimspace(split("|", line)[0])
      name          = trimspace(split("|", line)[1])
      url     = trimspace(split("|", line)[2])
    }
  ]
}
resource "meraki_network_webhook_http_server" "localalerts" {
  for_each = {
    for net in local.localalerts : net.name => net
  }
  network_id            = meraki_network.network[each.value.networkname].id
  name       = each.value.name
  url            = each.value.url
  payload_template_payload_template_id = "wpt_00002"
}