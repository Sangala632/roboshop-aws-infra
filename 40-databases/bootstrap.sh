#!/bin/bash

component=$1
dnf install -y python3
dnf install -y python3-boto3 python3-botocore
dnf install -y gcc python3-devel

dnf install ansible -y
ansible-pull -U https://github.com/Sangala632/ansible-roboshop-roles-tf.git -e component=$1 -e env=$2 main.yaml