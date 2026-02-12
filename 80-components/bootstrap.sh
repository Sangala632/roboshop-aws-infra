#!/bin/bash

component=$1
dnf install ansible -y
dnf install ansible -y
dnf install epel-release -y

dnf install python3-pip python3-devel -y
sudo pip3 install boto3 botocore
ansible-galaxy collection install amazon.aws
ansible-pull -U https://github.com/Sangala632/ansible-roboshop-roles-tf.git -e component=$1 -e env=$2 main.yaml