#!/bin/bash

## All credits go to https://github.com/aws-samples/aws-serverless-workshop-innovator-island
## where this script was found initially.

set -euxo pipefail

CURRENT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

export INFOPATH="/home/linuxbrew/.linuxbrew/share/info"

function _logger() {
    echo -e "$(date) ${YELLOW}[*] $@ ${NC}"
}

function upgrade_sam_cli() {
    _logger "[+] Backing up current SAM CLI"
    cp $(which sam) ~/.sam_old_backup

    _logger "[+] Installing latest SAM CLI"
    # pipx install aws-sam-cli
    # cfn-lint currently clashing with SAM CLI deps
    ## installing SAM CLI via brew instead
    brew tap aws/tap
    brew install aws-sam-cli

    _logger "[+] Updating Cloud9 SAM binary"
    # Allows for local invoke within IDE (except debug run)
    ln -sf $(which sam) ~/.c9/bin/sam
}

function upgrade_existing_packages() {
    _logger "[+] Upgrading system packages"
    sudo yum update -y

    _logger "[+] Upgrading Python pip and setuptools"
    python3 -m pip install --upgrade pip setuptools --user

    _logger "[+] Installing latest AWS CLI"
    # _logger "[+] Installing pipx, and latest AWS CLI"
    # python3 -m pip install --user pipx
    # pipx install awscli
    python3 -m pip install --upgrade --user awscli
}

function install_utility_tools() {
    _logger "[+] Installing CFN Linting"
    python3 -m pip install --upgrade --user cfn-lint

    _logger "[+] Installing c9 (Cloud9 CLI)"
    npm install -g c9
}

function configure_aws_cli() {
    _logger "[!] Overriding AWS CLI configuration... don't forget to attach IAM Role to EC2"
    rm -f ~/.aws/credentials
    cat <<-EOF >~/.aws/config
[default]
output = json
region = ${CURRENT_REGION}

EOF
}

function install_linuxbrew() {
    _logger "[+] Creating touch symlink"
    sudo ln -sf /bin/touch /usr/bin/touch
    _logger "[+] Installing homebrew..."
    echo | sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
    _logger "[+] Adding homebrew in PATH"
    test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
    test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
    echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
}

function upgrade_golang() {
  _logger "[+] Installing latest golang via homebrew"
  brew install golang
}

function main() {
    upgrade_existing_packages
    install_linuxbrew
    install_utility_tools
    upgrade_sam_cli
    upgrade_golang

    echo -e "${RED} [!!!!!!!!!] Open up a new terminal to reflect changes ${NC}"
    _logger "[+] Restarting Shell to reflect changes"
    exec ${SHELL}
}

main
