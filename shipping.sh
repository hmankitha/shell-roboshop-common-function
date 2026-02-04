#!/bin/bash

source ./common.sh

app_name=shipping

check_root

java_setup
app_setup
systemd_setup

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing MySQL"

mysql -h "$MYSQL_HOST" -u root -pRoboShop@1 -e 'use cities' &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h "$MYSQL_HOST" -u root -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
    mysql -h "$MYSQL_HOST" -u root -pRoboShop@1 < /app/db/app-user.sql &>>$LOGS_FILE
    mysql -h "$MYSQL_HOST" -u root -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
    VALIDATE $? "Loaded data into MySQL"
else
    echo -e "Data already loaded ... $Y SKIPPING $N"
fi

app_restart
print_total_time