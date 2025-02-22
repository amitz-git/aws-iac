# EC2 with EFS

**Teraform commond to build the Infrastructure**

```sh
terraform init
terraform plan
terraform apply --auto-approve
```
> terraform will generate the `inventory.ini` dynamically! to be used for ansible

**Ansible to mount efs volume to ec2**

```sh
ansible-playbook -i inventory.ini playbook.yml
```

**Login to EC2 and check if it's been mount or not**

```sh
df -k
```

**Clean the infrastructure**

```sh
terraform destroy --auto-approve
```