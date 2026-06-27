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
echo "Script execution started at: $(date)" | tee -a $LOG_FILE
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

spinner() {
    local pid=$1
    local delay=0.04  # High speed for fluid, buttery motion
    local i=0
    
    # 26-STAGE HORIZONTAL VECTOR SHIFT: High frame count for seamless wave cascading
    local spinstr=(
        '⠁  ' '⠃  ' '⠇  ' '⠇⠁ ' '⠇⠃ ' '⠇⠇ ' '⠇⠇⠁' '⠇⠇⠃' '⠇⠇⠇' 
        '⢎⠇⠇' '⢱⢎⠇' '⢀⢱⢎' ' ⢀⢱' '  ⢀' '   ' '⢀  ' '⢄⢀ ' 
        '⢆⢄⢀' '⢎⢆⢄' '⠇⢎⢆' '⠇⠇⢎' '⠇⠇⠇' '⠖⠇⠇' '⠤⠖⠇' ' ⠤⠖' '  ⠤'
    )
    local frame_count=${#spinstr[@]}
    
    # Hide the cursor safely
    tput civis 2>/dev/null 

    # Runs flawlessly frame-by-frame with zero sequence stutters
    while kill -0 "$pid" 2>/dev/null; do
        # Your exact text layout preserved. Replaces %s cleanly with the multi-dot wave
        printf "\r$2... [%s]" "${spinstr[i]}"
        
        i=$(( (i + 1) % frame_count ))
        sleep $delay
    done
    
    # Wipe the trailing animation cleanly right before validation prints
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


print_total_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( END_TIME - START_TIME ))
    echo "Script execution completed at: $(date)" | tee -a $LOG_FILE
    echo "Total time taken: $TOTAL_TIME seconds" | tee -a $LOG_FILE
}
