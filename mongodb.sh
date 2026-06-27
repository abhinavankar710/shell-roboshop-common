#!/bin/bash

source ./common.sh

check_root

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "MongoDB Repository Setup"

dnf list installed mongodb-org &>>$LOG_FILE
if [ $? -ne 0 ]; then
    # --- THE FIX STARTS HERE ---
    # We run the install AND save the exit code to a file inside this block ( )
    (
        dnf install -y mongodb-org &>>$LOG_FILE
        echo $? > /tmp/mongo_status
    ) & 
    
    pid=$!
    spinner $pid "Installing MongoDB"
    wait $pid
    
    # We read the code from the file so it is NEVER empty
    EXIT_STATUS=$(cat /tmp/mongo_status)
    
    # We validate using that solid number
    VALIDATE $EXIT_STATUS "MongoDB Installation"
    # --- THE FIX ENDS HERE ---
    
else
    echo -e "MongoDB already exists...${Y}Skipping${N}" | tee -a $LOG_FILE
fi

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB Service"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Executing MongoDB Service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing Remote Connections to MongoDB"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB Service"

print_total_time