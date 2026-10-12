output "api_ip" {
  description = "Public IP of the API server"
  value       = module.app_servers["api"].public_ip
}

output "payments_ip" {
  description = "Public IP of the Payments server"
  value       = module.app_servers["payments"].public_ip
}

output "logs_ip" {
  description = "Public IP of the Logs server"
  value       = module.app_servers["logs"].public_ip
}