#!/bin/bash
# KijaniKiosk IaC Pipeline: Terraform -> Ansible

set -e 

echo "==================================================="
echo " Phase 1: Infrastructure Provisioning (Terraform) "
echo "==================================================="
cd terraform
terraform init
terraform apply -auto-approve

echo -e "\n==================================================="
echo " Phase 2: Dynamic Inventory Generation "
echo "==================================================="
API_IP=$(terraform output -raw api_ip)
PAYMENTS_IP=$(terraform output -raw payments_ip)
LOGS_IP=$(terraform output -raw logs_ip)

cd ../ansible

# Fix: Map the alias to the dynamic IP so host_vars are loaded correctly
cat << INVENTORY > inventory.ini
[all]
api ansible_host=$API_IP
payments ansible_host=$PAYMENTS_IP
logs ansible_host=$LOGS_IP

[api_group]
api

[payments_group]
payments

[logs_group]
logs
INVENTORY

echo "Generated inventory.ini with mapped AWS IPs:"
cat inventory.ini

echo -e "\n==================================================="
echo " Phase 3: Server Configuration (Ansible) "
echo "==================================================="
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini kijanikiosk.yml

echo -e "\n[SUCCESS] IaC Pipeline completed successfully."
