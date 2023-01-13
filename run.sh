# login as root and run. Do not use sudo as your environment variables are lost
# first source the environment file:
# source set_vault_password_env.sh
ansible-playbook -i collections/ansible_collections/eelcovv/ldx_webdev_server/plugins/inventory/inventory.yml all.yml 

