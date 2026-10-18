# twk-infra: a developer machine in the cloud, built with Terraform (AWS)

**Phase 1 of 10: Build the machine.**

One Terraform plan creates the network, the server and the storage I will write, test and push code from. This is my AWS version of a hands-on lab that was first built on Huawei Cloud. I copied the idea, then rebuilt it with AWS resources so I could learn how the two clouds map onto each other.

> Credit: based on the lab *"A developer machine in the cloud, built with Terraform"* by Tech With Kishky. The design is his. The AWS code and the notes on what changed are mine.

---

## What this builds

```
Your laptop (terraform, ssh, browser)
        |
        |  ssh :22 (my IP only)      browser :80 / :443
        v
  Elastic IP (fixed public address)
        |
+-------+--------------------------------------------+
|  AWS eu-west-1 (Ireland)                           |
|  VPC 10.60.0.0/16                                  |
|    Internet gateway --> public route table         |
|    Subnet 10.60.2.0/24 (eu-west-1a)               |
|      Security group: 22 from me, 80 and 443 open   |
|      EC2 "twk-dev": Ubuntu 22.04                   |
|        40 GiB root disk + 100 GiB data disk        |
+----------------------------------------------------+

  S3 bucket (private, versioned, encrypted): backups now, Terraform state later
```

The server is where I work. I log in over SSH, write and run code there, and push to GitHub from it. My laptop is only a terminal.

## Resources created (18 in total)

| What | AWS resource | File |
|---|---|---|
| Private network | `aws_vpc` | `network.tf` |
| Slice of the network for the server | `aws_subnet` | `network.tf` |
| Door to the internet | `aws_internet_gateway`, `aws_route_table`, `aws_route_table_association` | `network.tf` |
| Firewall | `aws_security_group` plus three inbound rules (SSH, HTTP, HTTPS) and one outbound rule | `network.tf` |
| SSH key (public half only) | `aws_key_pair` | `ec2.tf` |
| Server | `aws_instance` (the Ubuntu image is looked up with `data.aws_ami`) | `ec2.tf` |
| Fixed public address | `aws_eip`, `aws_eip_association` | `ec2.tf` |
| Storage bucket | `aws_s3_bucket`, plus public access block, versioning and encryption | `s3.tf` |

## Project structure

```
twk-infra/
├── versions.tf         # allowed Terraform and provider versions
├── provider.tf         # tells Terraform to use AWS and which region
├── variables.tf        # every setting, with types and defaults
├── network.tf          # VPC, subnet, internet access, firewall
├── ec2.tf              # image lookup, key pair, server, Elastic IP
├── s3.tf               # storage bucket and its protections
├── outputs.tf          # values printed after apply
├── Makefile            # shortcuts for the Terraform commands
├── terraform.tfvars    # MY values (never committed)
├── terraform.tfstate   # Terraform's memory (never committed)
└── tfplan              # saved plan (never committed)
```

## Settings I chose

| Setting | Value |
|---|---|
| Region and zone | `eu-west-1`, `eu-west-1a` |
| Instance type | `c7i-flex.large` (2 vCPU, 4 GiB RAM). The Huawei lab used 4 vCPU and 8 GB, which was not available on the AWS free tier, so this is the largest size I could use. |
| Operating system | Ubuntu 22.04 LTS from Canonical, newest build |
| Disks | 40 GiB root and 100 GiB data, both `gp3` and encrypted |
| Network | VPC `10.60.0.0/16`, subnet `10.60.2.0/24` |
| Tags on everything | `project=twk`, `env=dev`, `managed-by=terraform` |

Three values have no default, so I must supply them in `terraform.tfvars`:

```hcl
ssh_cidr        = "<my-public-ip>/32"           # curl -s ifconfig.me
ssh_public_key  = "ssh-rsa AAAA... me@my-machine"
s3_bucket_name  = "<globally-unique-bucket-name>"
```

## Before you start

1. **Terraform** 1.5 or newer (`terraform version`). See `versions.tf` for the exact rule.
2. **An AWS account and an IAM user** with permission to create networks, EC2, Elastic IPs and S3.
3. **AWS credentials on your machine.** I used `aws configure`, which stores them in `~/.aws/credentials`. Terraform finds them there, so no keys appear in any project file. Check with:
   ```bash
   aws configure list
   aws sts get-caller-identity
   ```
4. **An SSH key pair.** The private key stays on my laptop. Only the `.pub` half goes into `terraform.tfvars`.
5. **My public IP**, because the firewall lets only that address use SSH.

## How to run it

Run these in the project folder, one at a time, and read the output of each.

```bash
terraform fmt                 # tidy the files
terraform init                # download the AWS provider
terraform validate            # check the files make sense (does not contact AWS)
terraform plan -out=tfplan    # preview, and save exactly what was previewed
terraform apply tfplan        # create it (this is when billing starts)
```

Then look at what Terraform now tracks:

```bash
terraform state list
terraform output
```

Note: `plan` takes `-out=tfplan` to *save* a plan. `apply` takes `tfplan` to *use* it. The Makefile wraps the same commands.

## Connect to the server

```bash
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw ec2_public_ip)
```

The login user on Ubuntu AMIs in AWS is `ubuntu`. The Huawei lab used `root`, which is a difference to remember.

When I first tried `root@...` the server refused me and printed a message telling me to log in as the user `ubuntu` instead of `root`. That message is useful: it also proves the network, firewall and key were all working, because the server answered. Only the user name was wrong, so I changed `root` to `ubuntu`.

If SSH times out, my home IP has probably changed. Compare `curl -s ifconfig.me` with `ssh_cidr` in `terraform.tfvars`, update it, then plan and apply again.

## Outputs

`vpc_id`, `dev_subnet_id`, `security_group_id`, `ec2_id`, `ec2_private_ip`, `ec2_public_ip`, `ec2_public_dns`, `s3_bucket`. The one I use most is `ec2_public_ip`.

## Huawei Cloud to AWS: what changed

| Idea | Huawei lab | My AWS version |
|---|---|---|
| Provider | `huaweicloud` | `aws` |
| Server | `huaweicloud_compute_instance`, flavor `s6.xlarge.2` (4 vCPU, 8 GB) | `aws_instance`, type `c7i-flex.large` (2 vCPU, 4 GiB), because 4 vCPU / 8 GB is not on the free tier |
| File names | `ecs.tf` (Huawei's Elastic Cloud Server) and `obs.tf` (Object Storage Service) | `ec2.tf` (AWS EC2) and `s3.tf` (AWS S3) |
| Image | Public image looked up by name | `aws_ami` looked up from Canonical's owner ID |
| Firewall | `huaweicloud_networking_secgroup` | `aws_security_group` with separate `aws_vpc_security_group_*_rule` resources |
| Internet access | Built into the subnet | Needs an **internet gateway and route table** that I create myself |
| Public IP | `huaweicloud_vpc_eip` plus association | `aws_eip` plus `aws_eip_association` |
| Bucket | `huaweicloud_obs_bucket`, with versioning as one setting | `aws_s3_bucket` split into separate resources for versioning, encryption and public access block |
| Billing groups | `enterprise_project_id` | No AWS equivalent |
| First login user | `root` | `ubuntu` |

Things I added that the Huawei lab did not have: encrypted disks, an explicit outbound rule (Terraform removes AWS's default outbound rule when it manages a security group), and `http_tokens = "required"` on the instance, which forces the safer version of the instance metadata service.

## What happened when I ran it

My first `apply` created the network and the server but failed on the S3 bucket. Three things came out of it.

**1. S3 `CreateBucket` failed with `no such host`.**
The error said my machine could not resolve `twk-lab-storage.s3.eu-west-1.amazonaws.com`. That is a name lookup failure, not a permissions or code problem. I checked the other possibilities first: `aws configure list` and `aws sts get-caller-identity` showed my credentials and region were fine, and `curl -I https://aws.amazon.com` worked. `nslookup` then resolved the S3 names normally. It looks like a temporary DNS hiccup in my WSL setup. Lesson: when an error says `no such host`, test DNS before touching the Terraform.

**2. `Saved plan is stale`.**
Re-running `terraform apply tfplan` failed because the first apply had already changed the state. A saved plan is only valid for the state it was made against. The fix is to make a fresh plan and read it. Terraform remembered the 14 resources already created and the new plan listed only the 4 S3 resources still missing: `Plan: 4 to add, 0 to change, 0 to destroy`.

**3. `Too many command line arguments`.**
I typed `terraform plan tfplan` by mistake. `plan` saves with `-out=tfplan`. Only `apply` takes the file name.

**Logging in as root was refused.**
See "Connect to the server" above. The fix was changing the SSH user from `root` to `ubuntu`.

**One more thing I noticed.** The fresh plan said `public_dns` on the server had "changed outside of Terraform". The instance first got an automatic public address, and when the Elastic IP was attached it took over, so the DNS name changed. The Elastic IP is the stable address, and `ec2_public_ip` is the output to rely on, not `ec2_public_dns`.

Final result: `Apply complete! Resources: 4 added, 0 changed, 0 destroyed.` The first run added 14, so the project is 18 resources in total.

## Safety and cost

**Never commit** `terraform.tfstate`, `terraform.tfstate.backup`, `terraform.tfvars`, `tfplan` or any credentials. State and plan files can contain secrets. A `.gitignore` should list them, and `.terraform.lock.hcl` should be committed.

**Costs money while it exists:** the server, the two disks, the Elastic IP (AWS bills for public IPv4 addresses) and the bucket. Check prices in the AWS calculator and set a budget alert.

**Drift:** if I change something by hand in the AWS console, Terraform does not know. Make every change in the `.tf` files.

**Tearing it down.** The VPC, server and bucket have `prevent_destroy = true`, so `terraform destroy` refuses on purpose. To delete everything:

```bash
sed -i.bak 's/prevent_destroy = true/prevent_destroy = false/' network.tf ec2.tf s3.tf
terraform plan -destroy -out=destroyplan
# read every line, then:
terraform apply destroyplan
```

## Known cleanup

- `enterprise_project_id` and `image_name` in `variables.tf` are left over from the Huawei version. Nothing uses them.

## What comes next

The server is a blank Ubuntu machine. Phase 2 makes it safe to work on: a normal user, key-only SSH, and how to rebuild if I lock myself out. Phase 3 formats and mounts the 100 GiB data disk, which arrives blank.