#!/bin/bash

source ./common.sh

check_root

dnf list installed mysql-server &>>$LOG_FILE 
if [ $? -ne 0 ]; then  
    # --- THE FIX STARTS HERE ---
    # We run the install AND save the exit code to a file inside this block ( )
    (
        dnf install -y mysql-server &>>$LOG_FILE
        echo $? > /tmp/mysql_status
    ) & 
    
    pid=$!
    spinner $pid "Installing MySQL"
    wait $pid
    
    # We read the code from the file so it is NEVER empty
    EXIT_STATUS=$(cat /tmp/mysql_status)
    
    # We validate using that solid number
    VALIDATE $EXIT_STATUS "MySQL Installation"
    # --- THE FIX ENDS HERE ---
    
else
    echo -e "MySQL already exists$Y SKIPPING$N installation of MySQL" | tee -a $LOG_FILE
fi

systemctl enable mysqld &>>$LOG_FILE &
pid=$!
spinner $pid "Enabling MySQL Service"
wait $pid
VALIDATE $? "Enabling MySQL Service"

systemctl start mysqld &>>$LOG_FILE &
pid=$!
spinner $pid "Starting MySQL Service"
wait $pid
VALIDATE $? "Starting MySQL Service"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting root password for MySQL Server"

print_total_time