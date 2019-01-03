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

# Enterprise Demo Setup

## Step 1: Use Packer to build AMIs
0. change to the packer directory `packer/`
1. Download Consul, Nomad, and Vault binaries locally (Vault enterprise required, Consul and Nomad Enterprise )
2. Copy packer/vars.json.example to packer/vars.json
3. Configure variables local path to those binaries in packer/vars.json
4. Ensure AWS credentials are exposed as environment variables
5. Expose AWS environment variables to avoid AMI copy timeouts. `export AWS_MAX_ATTEMPTS=60 && export AWS_POLL_DELAY_SECONDS=60`
6. Execute Packer build
```
cd packer
# Download enterprise binaries and add variables to vars.json (copied from vars.json.example)
# CentOS 7(default)
packer build -var-file=vars.json -only=amazon-ebs-centos-7 packer.json   
# RHEL 7.5 - Additional licensing costs
packer build -var-file=vars.json -only=amazon-ebs-rhel-7.5-systemd packer.json   
```

## Step 2: Terraform Enterprise  
[TFE URL](app.terraform.io). This setup assumes you have a TFE SaaS account and a VCS connection setup. You could also push the code up via the enhanced remote backend, TFE-CLI, or API.

0. [Create a workspace](https://www.terraform.io/docs/enterprise/workspaces/creating.html) in TFE for musical-spork. I'm calling it the "Hashi-Stack" here for demo purposes. (Note the workspace settings from the below image)

![](https://raw.githubusercontent.com/Andrew-Klaas/musical-spork/master/assets/create_workspace.png)

1. [Configure variables
](https://www.terraform.io/docs/enterprise/workspaces/variables.html) for the workspace. I'm doing it via the GUI here.

![](https://raw.githubusercontent.com/Andrew-Klaas/musical-spork/master/assets/configure_variables.png)


2. (Optional, but highly recommended) Add some [Sentinel Policies](https://www.terraform.io/docs/enterprise/sentinel/index.html) to your TFE workspace. [Examples](https://www.terraform.io/docs/enterprise/sentinel/examples.html)

![](https://raw.githubusercontent.com/Andrew-Klaas/musical-spork/master/assets/sentinel_policy.png)

3. Queue a terraform plan. Show plan and policy check results. The demo is around 140 resources at the time of writing. Your policy checks will most likely differ :).

![](https://raw.githubusercontent.com/Andrew-Klaas/musical-spork/master/assets/plan.png)


4. Run Apply
5. Next steps: See following links for business value demo walkthroughs. [TODO LINK](). You will use the terraform output from this workspace for your demos.




## Terraform OSS usage (Use TFE if possible)

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
