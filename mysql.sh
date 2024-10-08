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
        # here tee command will append the result in logfile before | (pipe) it will print on the terminal also
        #if your using tee command the no need of &>>
        echo -e "$R please run the script with root privilages $N" | tee -a $LOG_FILE
        exit 1
    fi
}

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R FAILED.. Check it.$N" | tee -a $LOG_FILE
    else
        echo -e "$2 is $G SUCESSES...$N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE
CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE
validate $? "Installing mysql server.."

systemctl enable mysqld &>>$LOG_FILE
validate $? "enables mysql server.."

systemctl start mysqld &>>$LOG_FILE
validate $? "started mysql server.."

mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
mysql -h mysqldb.basavadevops81s.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    echo "MySQL root password is not setup, setting now" &>>$LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1
    validate $? "setting up root password.."
else
    echo -e "MySQL root password is already setup...$Y SKIPPING $N" | tee -a $LOG_FILE
fi


# Assignment1
# check MySQL Server is installed or not, enabled or not, started or not
# implement the above things
