#!/bin/bash

# Variable of directory that we'll check the size of
DIR='/home'

# Email address we'll send alerts to
MAILTO='ENTER YOUR EMAIL ADDRESS HERE'

# Variable SUBJECT holds email's subject
SUBJECT="SERVER STATUS: $(hostname -f)"

# Check if mailx is installed and assign it's path to a variable
MAILX="$(which mailx)"

# Define the log file
LOGFILE=$HOME/vesta-server-mon.log

# Manual set the environment so it accepts non ASCII characters https://stackoverflow.com/a/18717024/5211506
export LC_CTYPE="el_GR.UTF-8"

# Throw error and exit if mailx is not installed
if [[ $MAILX == "" ]]
	then
	  echo "Please install mailx"
	#Here we warn user that mailx not installed
	  exit 1
	#Here we will exit from script
fi

# This will print space usage by each directory inside directory $DIR, and after MAILX will send email with SUBJECT to MAILTO
	echo "##### DISK USAGE FOR $DIR #####" > $LOGFILE
	du -sh ${DIR}/* | sort -hr >> $LOGFILE 2>&1
	echo "" >> $LOGFILE

# Check MailQueue
	echo "##### CHECKING THE MAIL QUEUE #####" >> $LOGFILE
	/usr/sbin/exim -bp | /usr/sbin/exiqsumm >> $LOGFILE 2>&1
# Check free space
	echo "##### CHECKING FREE SPACE #####" >> $LOGFILE
	df -Tha --total >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Check free memory
	echo "##### CHECKING FREE MEMORY #####" >> $LOGFILE
	free -mt >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Perform rsync
	echo "##### CHECKING RSYNC BACKUP #####" >> $LOGFILE
	rsync -ahv --no-g -e "ssh -p 22 -i /root/rsync_key" /backup/ root@YOURSERVER:/v-bakcup/$(hostname -f) >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Check fail2ban
	echo "##### CHECKING FAIL2BAN #####" >> $LOGFILE
	/usr/sbin/service fail2ban status >> $LOGFILE 2>&1
	echo "
	##### CHECKING JAIL SSH #####" >> $LOGFILE
	fail2ban-client status ssh-iptables >> $LOGFILE 2>&1
	echo "
	##### CHECKING JAIL DOVECOT #####" >> $LOGFILE
	fail2ban-client status dovecot-iptables >> $LOGFILE 2>&1
	echo "
	##### CHECKING JAIL EXIM #####" >> $LOGFILE
	fail2ban-client status exim-iptables >> $LOGFILE 2>&1
	echo "
	##### CHECKING JAIL MYSQL #####" >> $LOGFILE
	fail2ban-client status mysqld-iptables >> $LOGFILE 2>&1
	echo "
	##### CHECKING JAIL VSFTPD #####" >> $LOGFILE
	fail2ban-client status vsftpd-iptables >> $LOGFILE 2>&1
	echo "
	##### CHECKING JAIL VESTA #####" >> $LOGFILE
	fail2ban-client status vesta-iptables >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Check the number of outgoing messages per user
	echo "##### CHECKING NUMBER OF MESSAGES PER USER #####" >> $LOGFILE
	grep '<=' /var/log/exim4/mainlog | awk '{print $5}' | grep \@ | sort | uniq -c | sort -nrk1  >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Check failures in DNS
	echo "##### CHECKING DNS FAILURES #####" >> $LOGFILE
	tail -c 8192 /var/log/syslog | grep denied >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Clean PHP session files older than 8h
        for d in /home/*; do /usr/bin/find $d/tmp/sess_* -mmin +480 ; done
# Send email alert
	$MAILX -r root -s "$SUBJECT" "$MAILTO" < $LOGFILE 2>&1
