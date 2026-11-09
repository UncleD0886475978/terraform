# BUILD — terraform

## One-line install (fresh Ubuntu/Debian VM)

```bash
curl -fsSL https://raw.githubusercontent.com/UncleD0886475978/terraform/main/setup.sh | bash
```

The script installs its own prerequisites — git/curl via apt and Terraform from the official HashiCorp apt repository — then clones the repo and validates. Alternative (clone-and-run): `git clone https://github.com/UncleD0886475978/terraform.git && cd terraform && ./setup.sh`.

- Repo: UncleD0886475978/terraform — Public **fork**
- Stack actually found: Flat collection of standalone Terraform/AWS learning examples, not one stack. Proving files: ~25 root `.tf` files including `simple-ec2-instance.tf`, `custom-vpc-with-ec2-instances.tf`, `s3_bucket.tf`, `vpc-subnet-network.tf`, `webserver-elb.tf`, `multiple-ec2-instances.tf`, `workspaces.tf`, plus extension-less example files (`cluster-webserver-with-asg-alb`, `state-file-on-s3`, `terraform-module`, etc.) and `install_apache.sh`; `README.md` is only 53 B.
- What setup.sh does: Bootstraps base tools (git/curl) via apt, locates/clones the repo, bootstraps terraform (HashiCorp apt repo; on non-apt platforms it prints install guidance and exits), runs `terraform init -backend=false` + `validate` at root with validate failure explicitly tolerated/explained (examples duplicate names), and shows how to validate/apply ONE example in isolation in /tmp. Prints a bootstrap summary (installed tools, working copy, one-line reinstall command).
- Issue it prevents: Applying the whole flat folder at once and colliding/booting a pile of duplicate AWS resources.
- Inspection note: root listing for every repo succeeded via GitHub connector. Deeper file reads were halted by a GitHub MCP HTTP 429 (rate limit) after willow-creek's subdirs/README were read; no further connector calls were made after the 429. Scripts therefore discover files at runtime where subdir contents were not individually enumerated. Root listing was complete (flat repo, no subdirs listed).
