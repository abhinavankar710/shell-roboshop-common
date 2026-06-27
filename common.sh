#!/bin/bash

check_root(){
    USERID=$(id -u)
        if [ $USERID -ne 0 ]; then
            echo "ERROR: Please run this script with root privileges"
            exit 1
        fi
}

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOGS_FOLDER
START_TIME=$(date +%s)
MONGODB_HOST=mongodb.ankar.space
echo "Script execution started at: $(date)" | tee -a $LOG_FILE
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

spinner() {
    local pid=$1
    local delay=0.1
    local -a spinstr=(🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘)
    tput civis 2>/dev/null 
    while kill -0 $pid 2>/dev/null; do
        for char in "${spinstr[@]}"; do
            printf "\r$2...%s" "$char"
            sleep $delay
            kill -0 $pid 2>/dev/null || break
        done
    done
    printf "\r\033[K"
    tput cnorm 2>/dev/null 
}



VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2...$R✗ Failed$N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2...$G✓ Success$N" | tee -a $LOG_FILE
    fi
}

nodejs_setup(){
    dnf module disable nodejs -y &>>$LOG_FILE &
    pid=$! 
    spinner $pid "Disabling Default NodeJS Module"
    wait $pid
    dnf module enable nodejs:20 -y &>>$LOG_FILE &
    pid=$!
    spinner $pid "Enabling NodeJS 20 Module"
    wait $pid
    dnf list installed nodejs &>>$LOG_FILE 
    if [ $? -ne 0 ]; then  
        # --- THE FIX STARTS HERE ---
        # We run the install AND save the exit code to a file inside this block ( )
        (
            dnf install -y nodejs &>>$LOG_FILE
            echo $? > /tmp/nodejs_status
        ) & 
        
        pid=$!
        spinner $pid "Installing NodeJS"
        wait $pid
        
        # We read the code from the file so it is NEVER empty
        EXIT_STATUS=$(cat /tmp/nodejs_status)
    else
        echo -e "NodeJS already exists$Y SKIPPING$N installation of NodeJS" | tee -a $LOG_FILE
    fi
    cd /app 
    npm install &>>$LOG_FILE &
    pid=$!
    spinner $pid "Installing NodeJS Dependencies"
    wait $pid
    VALIDATE $? "Installing NodeJS Dependencies"
}

app_setup(){
    mkdir -p /app &>>$LOG_FILE
    VALIDATE $? "Setting up Application Directory"
    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE &
    pid=$!
    spinner $pid "Downloading Application Code"
    wait $pid
    VALIDATE $? "Downloading Application Code"
    cd /app
    VALIDATE $? "Changing to application Directory"
    rm -rf /app/* &>>$LOG_FILE
    VALIDATE $? "Removing existing Application Code"
    unzip -o /tmp/$app_name.zip &>>$LOG_FILE &
    pid=$!
    spinner $pid "Extracting Application Code"
    wait $pid
    VALIDATE $? "Extracting Application Code"
}

systemd_setup(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service &>>$LOG_FILE
    VALIDATE $? "Copying SystemD $app_name Service File"

    systemctl daemon-reload &>>$LOG_FILE &
    pid=$!
    spinner $pid "Reloading SystemD"
    wait $pid
    VALIDATE $? "Reloading SystemD"

    systemctl enable $app_name &>>$LOG_FILE &
    pid=$!
    spinner $pid "Enabling $app_name Service"
    wait $pid
    VALIDATE $? "Enabling $app_name Service"
}

app_restart(){
    systemctl restart $app_name &>>$LOG_FILE &
    pid=$!
    spinner $pid "Restarting $app_name Service"
    wait $pid
    VALIDATE $? "Restarting $app_name Service"
}

print_total_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( END_TIME - START_TIME ))
    echo "Script execution completed at: $(date)" | tee -a $LOG_FILE
    echo "Total time taken: $TOTAL_TIME seconds" | tee -a $LOG_FILE
}