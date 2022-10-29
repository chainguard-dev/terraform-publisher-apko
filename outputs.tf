output "uptime-check" {
  value = local.use_gclb ? google_monitoring_uptime_check_config.global-uptime-check[0].uptime_check_id : google_monitoring_uptime_check_config.regional-uptime-check[0].uptime_check_id
}
