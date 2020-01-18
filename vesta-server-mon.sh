#!/bin/bash

# Variable of directory that we'll check the size of
DIR='/home'

# Email address we'll send alerts to
MAILTO='[CHANGE ME]'

# Variable SUBJECT holds email's subject
SUBJECT="SERVER STATUS: $(hostname -f)"

# Check if mailx is installed and assign it's path to a variable
MAILX="$(which mailx)"

# Define the log file / Same name as script file but with .log extension
LOGFILE=$0.log

# rsync variables (ssh key, local backup directory, remote backup directory, backup server)
RSYNKEY=$HOME/rsa-key-backup.key
LOCABAK=/backup/
REMOBAK=/v-backup
BAKFOLD=[CHANGE ME]		# No slashes
BAKSERV=[CHANGE ME]		# Hostname or IP address
BAKUSER=[CHANGE ME]		# Hostname or IP address

# Manual set the environment so it accepts non ASCII characters https://stackoverflow.com/a/18717024/5211506
export LC_CTYPE="el_GR.UTF-8"

# Check if this is a VESTA or HESTIA installation
[[ -d /usr/local/vesta/ ]] && CPNAME=vesta
[[ -d /usr/local/hestia/ ]] && CPNAME=hestia

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

# This will print inode usage for /home directory
	echo "##### INODE USAGE #####" >> $LOGFILE
	df -hi >> $LOGFILE 2>&1
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
	rsync -ahv --no-g -e "ssh -p 22 -i $RSYNKEY" $LOCABAK $BAKUSER@$BAKSERV:$REMOBAK/$BAKFOLD/$(hostname -f) >> $LOGFILE 2>&1
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
	fail2ban-client status $CPNAME-iptables >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Check the number of outgoing messages per user
	echo "##### CHECKING NUMBER OF MESSAGES PER USER #####" >> $LOGFILE
	grep '<=' /var/log/exim4/mainlog | awk '{print $5}' | grep \@ | sort | uniq -c | sort -nrk1  >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Check failures in DNS
	echo "##### CHECKING DNS FAILURES #####" >> $LOGFILE
	tail -c 8192 /var/log/syslog | grep denied >> $LOGFILE 2>&1
	echo "" >> $LOGFILE
# Clean PHP session files older than 24h
        for d in /home/*; do /usr/bin/find $d/tmp/sess_* -mmin +1440 -delete; done &> /dev/null
# Send email alert
	$MAILX -r root -s "$SUBJECT" "$MAILTO" < $LOGFILE 2>&1
