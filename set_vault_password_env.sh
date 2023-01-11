#!/bin/bash
# 
# script: set_vault_password_env.sh
#
# usage: source set_vault_password_env.sh
#
# purpose: set the ANSIBLE_VAULT_PASSWORD environment variable
#
# requirements:
# 
# Copy the file vault-env.sh to your directory ~/.ansible in order to
# work together with ansible-vault

export ANSIBLE_VAULT_PASSWORD_FILE="$HOME/.ansible/vault-env"
export no_proxy='*'

read -sp "Vault password:" ANSIBLE_VAULT_PASSWORD
export ANSIBLE_VAULT_PASSWORD
echo " ************"
