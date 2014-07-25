#!/bin/bash

cd /home/dogbert/administration/transfer_adlm/
java BackupADML /mnt/pc19487/adl-m/csv_weekly/ /media/memory01/ei_data_exploratories/backup/incoming_gsm/csv_weekly/ /media/memory01/ei_data_exploratories/incoming/ /mnt/pc19487/adl-m/csv_moved_to_processing/  >> error_gsm_csv_files.log 2>&1

java BackupADML_ftp /mnt/pc19460/incoming_ftp/csv/ /media/memory01/ei_data_exploratories/backup/incoming_ftp/csv/ /media/memory01/ei_data_exploratories/incoming/ /mnt/pc19460/csv_moved_to_processing/ >> error_ftp_csv_files.log 2>&1

