# Overview
This contains HashiCorp code to do the following:  
1. Packer template to build an Ubuntu 18.04 image consisting of 'HashiStack', which is Consul, Nomad and Vault
2. Terraform code to provision the HashiStack in 2-3 separate AWS regions with peering
3. Automated cluster formation of Consul and Nomad in each region
4. Automated cluster formation of Vault in each region
5. Automated WAN joining of Consul and Nomad
6. Automated replication configuration of Vault clusters in each region

## Assumptions
- Packer and Terraform are available on local machine
- Vault Enterprise linux binary available locally (Consul Enterprise and Nomad Enterpise are optional)
- User possesses AWS account and credentials

