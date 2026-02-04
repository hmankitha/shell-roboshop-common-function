#!/bin/bash

source ./common.sh

check_root

cp mongo.repo /etc/yum.repos.d/mongo.repo 
VALIDATE $? "Copying Mongo Repo"

dnf install mongodb-org -y
VALIDATE $? "Installing Mongodb Server "

systemctl enable mongod
VALIDATE $? "Enable mongod"

systemctl start mongod
VALIDATE $? "started mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections" 

systemctl restart mongod
VALIDATE $? "Restarted mongodb"

print_total_time

