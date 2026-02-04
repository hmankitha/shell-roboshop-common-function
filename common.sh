#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-$user_name"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)
MONGODB_HOST=mongodb.ankitha.online

mkdir -p $LOGS_FOLDER 

echo "Script started executing at: $(date)" | tee -a $LOGS_FILE

check_root(){
if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi
}

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$(date "+%Y-%m-%d %H:%M:%S") | $2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else 
        echo -e "$(date "+%Y-%m-%d %H:%M:%S") | $2 ... $G SUCESS $N" | tee -a $LOGS_FILE
    fi    
}

nodejs_setup(){
     dnf module disable nodejs -y &>>$LOGS_FILE
    VALIDATE $? "Disabling Nodejs Default version"

    dnf module enable nodejs:20 -y &>>$LOGS_FILE
    VALIDATE $? "Enabling NodeJS 20"

    dnf install nodejs -y &>>$LOGS_FILE
    VALIDATE $? "Install NodeJS"

    npm install &>>$LOGS_FILE
    VALIDATE $? "installing the build tool"
}

java_setup(){
    dnf install maven -y &>>$LOGS_FILE
    VALIDATE $? "Installing Maven"

    cd /app 
    mvn clean package &>>$LOGS_FILE
    VALIDATE $? "Installing and Building $app_name"

    mv target/$app_name-1.0.jar $app_name.jar 
    VALIDATE $? "Moving and Renaming $app_name"
}

systemd_setup(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service &>>$LOGS_FILE
    VALIDATE $? "Created systemctl services"

    systemctl daemon-reload &>>$LOGS_FILE
    systemctl enable $app_name &>>$LOGS_FILE
    systemctl start $app_name &>>$LOGS_FILE
    VALIDATE $? "Starting and enabling $app_name"
}

app_setup(){

    id roboshop &>>$LOGS_FILE
    if [ $? -ne 0 ]; then

        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Creating system user"
    else 
        echo -e "roboshop user already exit ...$Y SKIPPING $N"
    fi


    mkdir -p /app &>>$LOGS_FILE
    VALIDATE $? "creating app directory"

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOGS_FILE
    VALIDATE $? "Downloading $app_name code"

    cd /app &>>$LOGS_FILE
    VALIDATE $? "Moving to app directory"

    rm -rf /app/*
    VALIDATE $? "Removing existing code"

    unzip /tmp/$app_name.zip &>>$LOGS_FILE
    VALIDATE $? "unziping the $app_name code"


}

print_total_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo -e "$(date "+%Y-%m-%d %H:%M:%S") Script execute in: $G $TOTAL_TIME seconds $N" | tee -a $LOGS_FILE
}

app_restart(){
    systemctl restart $app_name
    VALIDATE $? "Restarting $app_name"
}