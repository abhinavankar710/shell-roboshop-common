#!/bin/bash

source common.sh

check_root

dnf module disable redis -y &>>$LOG_FILE &
pid=$!
spinner $pid "Disabling Default Redis Module"
wait $pid
VALIDATE $? "Disabling Default Redis Module"

dnf module enable redis:7 -y &>>$LOG_FILE &
pid=$!
spinner $pid "Enabling Redis 7 Module"
wait $pid
VALIDATE $? "Enabling Redis 7 Module"

dnf list installed redis &>>$LOG_FILE 
if [ $? -ne 0 ]; then  
    # --- THE FIX STARTS HERE ---
    # We run the install AND save the exit code to a file inside this block ( )
    (
        dnf install -y redis &>>$LOG_FILE
        echo $? > /tmp/redis_status
    ) & 
    
    pid=$!
    spinner $pid "Installing Redis"
    wait $pid
    
    # We read the code from the file so it is NEVER empty
    EXIT_STATUS=$(cat /tmp/redis_status)
    
    # We validate using that solid number
    VALIDATE $EXIT_STATUS "Redis Installation"
    # --- THE FIX ENDS HERE ---
    
else
    echo -e "Redis already exists$Y SKIPPING$N installation of Redis" | tee -a $LOG_FILE
fi

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "Allowing Remote Connections to Redis"
VALIDATE $? "Disabling Redis Protected Mode"

systemctl enable redis &>>$LOG_FILE &
pid=$!
spinner $pid "Enabling Redis Service"
wait $pid
VALIDATE $? "Enabling Redis"

systemctl start redis &>>$LOG_FILE &
pid=$!
spinner $pid "Executing Redis Service"
wait $pid
VALIDATE $? "Executing Redis"

print_total_time