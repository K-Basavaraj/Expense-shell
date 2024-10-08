#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# synatx: [ /var/log/<script_folder>/<script_name>-<timetamp>.log ]
LOGS_FOLDER="/var/log/Expense/"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOGS_FOLDER

CHECK_ROOT() {
    if [ $USER_ID -ne 0 ]; then
        echo -e "$R please run the script with root privilages.$N" | tee -a $LOG_FILE
        exit 1
    fi
}

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R FAILED..CHECK IT. $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is $G SUCESSES.. $N" | tee -a $LOG_FILE
    fi
}

USER_ID=$(id -u)
echo "Script started executing at: $(date)" | tee -a $LOG_FILE
CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
validate $? "disabled defult nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "enabled nodejs:20"

dnf install nodejs -y &>> $LOG_FILE
validate $? "insatllation nodejs"

id expense &>> $LOG_FILE
if [ $? -ne 0 ]; then
    echo -e "expense user not exists... $G Creating $N" | tee -a $LOG_FILE
    useradd expense &>> $LOG_FILE
    validate $? "Creating expense user"
else
    echo -e "expense user already exists... $Y Skipping $N" | tee -a $LOG_FILE
fi

mkdir -p /app 
validate $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $LOG_FILE
validate $? "Downloading backend application code"

#Deployment
cd /app
rm -rf /app/* # remove the existing code
unzip /tmp/backend.zip
validate $? "Extracting backend application code"

npm install &>> $LOG_FILE
pwd

#download the dependencies.
npm install &>> $LOG_FILE
# We need to setup a new service in systemd so systemctl can manage this service [ already setup in service file diroctories ]
#Setup SystemD Expense Backend Service
cp /home/ec2-user/Expense-shell/servicefile/backend.service /etc/systemd/system/backend.service #absolute path and realtive path 

# load the data before running backend
dnf install mysql -y &>> $LOG_FILE
validate $? "Installing MySQL Client"

mysql -h mysqldb.basavadevops81s.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
validate $? "schema loading" 

systemctl daemon-reload >> $LOG_FILE
validate $? "Daemon reload"

systemctl enable backend >>& $LOG_FILE
validate $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
validate $? "Restarted Backend"