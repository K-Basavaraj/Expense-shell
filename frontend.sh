#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/Expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOGS_FOLDER

CHECK_ROOT() {
    if [ $USER_ID -ne 0 ]; then
        echo -e "$R please run the script with root privilages $N" | tee -a $LOG_FILE
        exit 1
    fi
}

USER_ID=$(id -u)
echo "Script started executing at: $(date)" | tee -a $LOG_FILE
CHECK_ROOT

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R FAILED.. CHECK IT.$N" | tee -a $LOG_FILE
    else
        echo -e "$2 is $G SUCESSES..$N" | tee -a $LOG_FILE
    fi
}

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installation Nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enabling nginx" 

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "start Nginix" 

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloding frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extract frontend code"

cp /home/ec2-user/Expense-shell/configfile/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarted Nginx"