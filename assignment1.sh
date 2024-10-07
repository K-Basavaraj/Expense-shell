#!/bin/bash

LOGS_FOLDER="/var/log/Expense/" #folder path Expense created  in  /var/log

SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #created scriptname with removing .sh here $0 redirctors which will give script name.

TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S) # creating time stamp

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log" #here creating strutured logfile

mkdir -p $LOGS_FOLDER #we dont have shell-script folder so for that we are creating

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT() {
    if [ $USER_ID -ne 0 ]; then
        echo -e "$R please run the script with root privilages $N" | tee -a $LOG_FILE
        exit 1
    fi
}

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R not success.. Check it.$N" | tee -a $LOG_FILE
    else
        echo -e "$2 is $G Sucessfull...$N" | tee -a $LOG_FILE
    fi
}

service(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R not enabled.. Check it.$N" | tee -a $LOG_FILE
    else
        echo -e "$2 is $G enabled...$N" | tee -a $LOG_FILE
         # Now check if the service is started
        if [ $3 -ne 0 ]; then
            echo -e "$2 is $R not started.. Check it.$N" | tee -a $LOG_FILE
        else
            echo -e "$2 is $G started...$N" | tee -a $LOG_FILE
        fi
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE
CHECK_ROOT

dnf list installed mysql-server &>>$LOG_FILE
if [ $? -ne 0 ]; then
    echo -e "$R mysql-server is not installed..going to install it..$N" &>>$LOG_FILE
    dnf install mysql-server -y &>>$LOG_FILE
    validate $? "Installing mysql-server" #here also i am calling validaing function again

    systemctl enable mysqld &>>$LOG_FILE
    enable_status=$?
    systemctl start mysqld &>>$LOG_FILE
    start_status=$?
    # Call the service function with the enable and start status
    service $enable_status "MySQL server" $start_status
else
    echo -e "$G Mysqlserver is already installed nothing to do.."
fi

# mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
mysql -h mysqldb.basavadevops81s.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    echo "MySQL root password is not setup, setting now" &>>$LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1
    validate $? "setting up root password.."
else
    echo -e "MySQL root password is already setup...$Y SKIPPING $N" | tee -a $LOG_FILE
fi

systemctl status mysqld | tee -a $LOG_FILE
netstat -lntp  | tee -a $LOG_FILE
ps -ef | grep mysqld | tee -a $LOG_FILE


: '
    line 58 and 61 The exit statuses of systemctl enable and systemctl start are captured in separate variables (enable_status and start_status) 
    and passed to the service function.
'