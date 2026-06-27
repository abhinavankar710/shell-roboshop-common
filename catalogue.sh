#!/bin/bash

source ./common.sh
app_name=catalogue
app_setup
nodejs_setup
systemd_setup

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE 
VALIDATE $? "Setting up MongoDB Repository File"

dnf list installed mongodb-mongosh -y &>>$LOG_FILE

if [ $? -ne 0 ]; then
    # --- THE FIX STARTS HERE ---
    # We run the install AND save the exit code to a file inside this block ( )
    (
        dnf install -y mongodb-mongosh &>>$LOG_FILE
        echo $? > /tmp/mongosh_status
    ) & 
    
    pid=$!
    spinner $pid "Installing MongoDB Client"
    wait $pid
    
    # We read the code from the file so it is NEVER empty
    EXIT_STATUS=$(cat /tmp/mongosh_status)
    
    # We validate using that solid number
    VALIDATE $EXIT_STATUS "MongoDB Client Installation"
    # --- THE FIX ENDS HERE ---
    
else
    echo -e "MongoDB Client already exists...${Y}Skipping${N}" | tee -a $LOG_FILE
fi

INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')" 2>>$LOG_FILE)
if [ $INDEX -lt 0 ]; then
    mongosh --host $MONGODB_HOST --file /app/db/master-data.js &>>$LOG_FILE &
    pid=$!
    spinner $pid "Importing Master Data to MongoDB"
    wait $pid
    VALIDATE $? "Importing Master Data to MongoDB"
else
    echo -e "Master data already exists...${Y}Skipping${N}" | tee -a $LOG_FILE
fi

app_restart
print_total_time