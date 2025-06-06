variable "usaregionalalerts_file" {
  description = "Relative path to the network file"
  default     = "USARegionalSiteAlertsList.txt"
}
locals {
  raw_regionalalertlines = split("\n", trimspace(file(var.usaregionalalerts_file)))

  regionalsitealerts = [
      for line in local.raw_regionalalertlines : {
      networkname          = trimspace(split("|", line)[0])
      name          = trimspace(split("|", line)[1])
      url     = trimspace(split("|", line)[2])
    }
  ]
}
resource "meraki_network_webhook_http_server" "regionalalerts" {
  for_each = {
    for net in local.regionalsitealerts : "${net.networkname}-${net.name}" => net
  }

  network_id                           = meraki_network.network[each.value.networkname].id
  name                                 = each.value.name
  url                                  = each.value.url
  payload_template_payload_template_id = "wpt_00002"
}
data "meraki_network_alerts_settings" "Regexisting" {
  for_each = {
    for net in local.regionalsitealerts : net.networkname => net
  }
  network_id = meraki_network.network[each.value.networkname].id
}
resource "meraki_network_alerts_settings" "regionalalerts_alerts" {
  for_each = {
    for net in local.regionalsitealerts : "${net.networkname}" => net
}
  network_id = meraki_network.network[each.value.networkname].id
  default_destinations_http_server_ids = distinct(
    concat(
      data.meraki_network_alerts_settings.Regexisting[each.key].default_destinations_http_server_ids,
      [meraki_network_webhook_http_server.regionalalerts["${each.value.networkname}-${each.value.name}"].id]
    )
  )
  alerts = [
    {
      type     = "settingsChanged"
      enabled  = true
    }
  ]
}