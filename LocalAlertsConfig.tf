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
data "meraki_network_alerts_settings" "existing" {
  for_each = {
    for net in local.localalerts : net.networkname => net
  }
  network_id = meraki_network.network[each.value.networkname].id
}
resource "meraki_network_alerts_settings" "localalerts_alerts" {
  for_each = {
    for net in local.localalerts : "${net.networkname}" => net
}
  network_id = meraki_network.network[each.value.networkname].id
  default_destinations_http_server_ids = distinct(
    concat(
      data.meraki_network_alerts_settings.existing[each.key].default_destinations_http_server_ids,
      [meraki_network_webhook_http_server.localalerts[each.value.name].id]
    )
  )
  alerts = [
    {
      type     = "settingsChanged"
      enabled  = true
    }
  ]
}