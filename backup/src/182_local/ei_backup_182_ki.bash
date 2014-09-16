#!/bin/bash
# This script creates a 30 day long rotating backup of the
# SOURCEPATH directory to the BACKUPPATH directory.
# Crontab entry: 0 4 * * * bash /home/dogbert/administration/backup/ei_backup_sd19006_eikistations.bash >> /home/dogbert/administration/backup/log_error_sd19006_eikistations.log 2>&1

SOURCEPATH='/mnt/sd19006/' 
BACKUPPATH='/media/dogbert/kili_backup/eikistations/'
BACKUPNAME='pc19006_data'
LOGPATH='/home/dogbert/backup_ki_182/logs/'

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

# ToDo (as dogbert):
# Create folder and mount source
# sudo mkdir /mnt/sd19006
# sudo chown dogbert:dogbert -R sd19006
# sshfs dogbert@192.168.191.182:/media/memory01/ei_data_kilimanjaro /mnt/sd19006/
#
# Create folder and start backup
# mkdir /home/dogbert/backup_ki_182
# mkdir /home/dogbert/backup_ki_182/logs
# copy ei_backup_182_ki.bash into /home/dogbert/backup_ki_182/
# sudo chmod +x ei_backup_182_ki.bash
# start script: bash ei_backup_182_ki.bash > log.txt 2>&1 &