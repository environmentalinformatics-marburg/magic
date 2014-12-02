#!/bin/bash

cd /home/eibestations/backup_adlm/
java BackupADML_ftp /mnt/pc19460/incoming_ftp/csv/ /media/memory01/ei_data_exploratories/backup/incoming_ftp/csv/ /media/memory01/ei_data_exploratories/incoming/ /mnt/pc19460/csv_moved_to_processing/ >> error_ftp_csv_files.log 2>&1

