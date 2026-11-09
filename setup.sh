#!/usr/bin/env bash
# setup.sh — terraform (fork: flat collection of standalone Terraform examples)
# VM BOOTSTRAP: on a fresh Ubuntu/Debian VM this script INSTALLS its own
# prerequisites (git/curl, Terraform) and then validates.
# Safe by design: Terraform is init + validate ONLY. Nothing is applied.
set -e
REPO="terraform"
echo "=== Setup: $REPO ==="

OWNER="UncleD0886475978"
RUN_ONELINE="curl -fsSL https://raw.githubusercontent.com/${OWNER}/${REPO}/main/setup.sh | bash"

echo "==> Step 1/5: Platform check + base bootstrap (git, curl)"
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "ERROR: this script needs root or sudo to install packages."
    exit 1
  fi
fi
APT=0
if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then APT=1; fi
INSTALLED=""
APT_UPDATED=""
note_installed() { INSTALLED="${INSTALLED} $1"; }
apt_update_once() {
  if [ -z "${APT_UPDATED}" ]; then $SUDO apt-get update -y; APT_UPDATED=1; fi
}
apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$@"
}
if [ "${APT}" -eq 1 ]; then
  BASE_PKGS=""
  command -v git >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} git"
  command -v curl >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} curl"
  [ -f /etc/ssl/certs/ca-certificates.crt ] || BASE_PKGS="${BASE_PKGS} ca-certificates"
  command -v gpg >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} gnupg"
  if [ -n "${BASE_PKGS}" ]; then
    echo "    Installing base tools:${BASE_PKGS}"
    # shellcheck disable=SC2086
    apt_install ${BASE_PKGS}
    note_installed "${BASE_PKGS}"
  else
    echo "    Base tools already present (git, curl, ca-certificates, gnupg)."
  fi
else
  echo "    Non-apt platform detected — bootstrap will only CHECK tools and print install guidance."
fi

# --- Per-tool installers ---
install_terraform() {
  if command -v terraform >/dev/null 2>&1; then echo "    terraform: already present ($(terraform version | head -n 1))"; return 0; fi
  [ "${APT}" -eq 1 ] || return 1
  echo "    Installing Terraform from the official HashiCorp apt repository..."
  curl -fsSL https://apt.releases.hashicorp.com/gpg | $SUDO gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "${VERSION_CODENAME}") main" | $SUDO tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  $SUDO apt-get update -y
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y terraform
  note_installed "terraform"
}

# --- Locate or clone ---
echo "==> Step 2/5: locate repo"
if [ -f "$0" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  SCRIPT_DIR="$PWD"
fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git remote -v 2>/dev/null | grep -q "$REPO"; then
  REPO_DIR="$(git rev-parse --show-toplevel)"; echo "Using current checkout: $REPO_DIR"
elif [ -d "${SCRIPT_DIR}/.git" ] && [ "$(basename "${SCRIPT_DIR}")" = "$REPO" ]; then
  REPO_DIR="${SCRIPT_DIR}"; echo "Using script location: $REPO_DIR"
elif [ -d "$HOME/repos/$REPO/.git" ]; then
  REPO_DIR="$HOME/repos/$REPO"; echo "Updating $REPO_DIR"; git -C "$REPO_DIR" pull --ff-only || echo "WARN: git pull failed, using existing checkout"
else
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is not installed. Install it: https://git-scm.com/downloads"
    exit 1
  fi
  mkdir -p "$HOME/repos"; git clone "https://github.com/$OWNER/$REPO.git" "$HOME/repos/$REPO"; REPO_DIR="$HOME/repos/$REPO"
fi
cd "$REPO_DIR"; echo "Repo dir: $REPO_DIR"

echo "==> Step 3/5: Bootstrap prerequisites (Terraform)"
MISSING_LIST=""
install_terraform || MISSING_LIST="${MISSING_LIST} terraform(https://developer.hashicorp.com/terraform/install)"
if [ -n "${MISSING_LIST}" ]; then
  echo "ERROR: could not auto-install on this platform. Missing:${MISSING_LIST}"
  echo "Install the tool(s) manually, then re-run this script."
  exit 1
fi
terraform version


echo "==> Step 4/5: count the flat example files"
echo "Found $(ls -1 *.tf 2>/dev/null | wc -l) top-level .tf examples (e.g. simple-ec2-instance.tf, custom-vpc-with-ec2-instances.tf, s3_bucket.tf, vpc-subnet-network.tf, webserver-elb.tf)"
echo "NOTE: These are independent learning examples in one flat directory, NOT one deployable stack — they reuse names and would conflict if applied together."
echo "==> Step 5/5: Terraform init + validate at root (validate is expected to warn/fail on duplicate example definitions)"
terraform init -backend=false || echo "WARN: init reported issues — common for an examples collection"
terraform validate || echo "WARN: validate failed as expected for mixed standalone examples — validate a single example in isolation instead (see Next commands)"
echo ""
echo "Deliberate deploy of ONE example (NOT run):"
echo "  mkdir -p /tmp/tf-one && cp simple-ec2-instance.tf /tmp/tf-one/main.tf && cd /tmp/tf-one && terraform init && terraform plan && terraform apply"
echo "WARNING: terraform apply creates real AWS resources (EC2, VPC, S3, ELB/ASG in some examples) that COST MONEY until destroyed."

cat <<EOF

=================== BOOTSTRAP SUMMARY ===================
Installed during this run:${INSTALLED:- (nothing — all tools were already present)}
Working copy: ${REPO_DIR}
Next time, set up from scratch on any fresh Ubuntu VM with one line:
  ${RUN_ONELINE}
=========================================================
EOF

echo ""
echo "=== Next commands ==="
echo "Run/use:  mkdir -p /tmp/tf-one && cp <one-example>.tf /tmp/tf-one/main.tf && cd /tmp/tf-one && terraform init && terraform plan"
echo "Stop:     cd /tmp/tf-one && terraform destroy"
echo "Logs:     cd /tmp/tf-one && terraform state list && terraform show"
