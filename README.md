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

## Packer Usage
1. Download Consul, Nomad, and Vault binaries locally (Vault enterprise required, Consul and Nomad Enterprise )
2. Copy packer/vars.json.example to packer/vars.json
3. Configure variables local path to those binaries in packer/vars.json
4. Ensure AWS credentials are exposed as environment variables
5. Expose AWS environment variables to avoid AMI copy timeouts. `export AWS_MAX_ATTEMPTS=60 && export AWS_POLL_DELAY_SECONDS=60`
6. Execute Packer build
```
cd packer
packer build -var-file=vars.json -only=amazon-ebs-rhel-7.5-systemd  packer.json   
```

## Terraform usage

Configure Terraform variables
```
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
```

Initialize Terraform  
```
cd terraform
terraform init
```

Terraform plan execution with summary of changes
```
terraform plan
```

Terraform apply to create infrastructure
```
terraform apply 

# apply execution without prompt
# terraform apply -auto-approve
```

Tear down infrastructure using Terraform destroy

```
terraform destroy -force
```
