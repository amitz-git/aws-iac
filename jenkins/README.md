# Jenkins Deployment and Node creation

It will install jenkins and join another 2 ec2 as slave node 

## Create infrastructure using terraform

```sh
terraform apply --auto-approve
```
**Run the ansible playbook**

```sh
ansible-playbook -i inventory.yml playbook.yml
```
