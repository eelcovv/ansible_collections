# login as root and run. Do not use sudo as your environment variables are lost
ansible-playbook -i eelcovv/ldx_webdev_server/plugins/inventory/inventory.yml all.yml --ask-vault-password

