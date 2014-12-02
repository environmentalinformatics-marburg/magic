#!/bin/bash
# This script creates a 30 day long rotating backup of the
# SOURCEPATH directory to the BACKUPPATH directory.
# Crontab entry: 0 4 * * * bash /home/dogbert/administration/backup/ei_backup_sd19006_eibestations.bash >> /home/dogbert/administration/backup/log_error_sd19006_eibestations.log 2>&1

sshfs dogbert@192.168.191.182:/media/memory01/ei_data_exploratories /mnt/sd19006/

SOURCEPATH='/mnt/sd19006/' 
BACKUPPATH='/media/dogbert/2064C55564C52E7A/backup/exploratories/'
BACKUPNAME='pc19006_data'
LOGPATH='/home/dogbert/'

# Get date for log file
date

# Check to make sure the folders exist, if not creates them.
/bin/mkdir -p ${BACKUPPATH}backup_${BACKUPNAME}.{0..30}

# Delete the oldest backup folder.
/bin/rm -rf ${BACKUPPATH}backup_${BACKUPNAME}.30

# Shift all the backup folders up a day.
for i in {30..1}
do
/bin/mv ${BACKUPPATH}backup_${BACKUPNAME}.$[${i}-1] ${BACKUPPATH}backup_${BACKUPNAME}.${i}
done

# Create the new backup hard linking with the previous backup.
# This allows for the least amount of data possible to be
# transfered while maintaining a complete backup.
/usr/bin/rsync -a -e --copy-links --copy-unsafe-links --delete --exclude=".*" --link-dest=${BACKUPPATH}backup_${BACKUPNAME}.1 --log-file=${LOGPATH}log_rsync_${BACKUPNAME}.log ${SOURCEPATH} ${BACKUPPATH}backup_${BACKUPNAME}.0/

