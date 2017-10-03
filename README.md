# vesta-server-mon
A Linux shell script for monitoring and reporting a VESTA Control Panel installation

# Variables
There are two places that you need to put your info. At first, configure the MAILTO variable at the top of the file `MAILTO='ENTER YOUR EMAIL ADDRESS HERE'` Then configure rsync backup at the line
`rsync -ahv -e "ssh -p 22 -i /root/rsync_key" /backup/ root@YOURSERVER:/v-bakcup/$(hostname -a) >> $LOGFILE 2>&1`
