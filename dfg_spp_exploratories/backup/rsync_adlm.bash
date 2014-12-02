#!/bin/bash

# -a fasst folgende Optionen zusammen: 
# -r kopiert Unterverzeichnisse 
# -l kopiert symbolische Links 
# -p behält Rechte der Quelldatei bei 
# -t behält Zeiten der Quelldatei bei, 
# -g behält Gruppenrechte der Quelldatei bei 
# -o behält Besitzrechte der Quelldatei bei (nur root) 
# -D behält Gerätedateien der Quelldatei bei (nur root)

10 6 * * * bash /home/eibestations/backup_adlm/start.bash  >> /home/eibestations/backup_adlm/error_transfer_adlm.log 2>&1

# Synchronisiert Adl-M Download-Ordner auf dem Windows-Rechner mit seinem Backup auf dem 182-er
0 7 * * * rsync -av /mnt/pc19487/adl-m/download /media/memory01/ei_data_exploratories/backup/incoming_gsm/adl-m/ >> /home/eibestations/backup_adlm/error_adlm_download.log 2>&1

# Synchronisiert Adl-M Backup Download-Ordner auf dem 182-er mit dem Download-Ordner auf dem 83-er
30 7 * * * rsync -av /media/memory01/ei_data_exploratories/backup/incoming_gsm/adl-m/ /mnt/pc19460/incoming_gsm/ >> /home/eibestations/backup_adlm/error_adlm_backup_83.log 2>&1

# Synchronisiert Adl-M Settings-Ordner auf dem Windows-Rechner mit seinem Backup auf dem 182-er
0 8 * * * rsync -av /mnt/pc19487/adl-m/settings /media/memory01/ei_data_exploratories/backup/adl-m_programe/ >> /home/eibestations/backup_adlm/error_adlm_settings.log 2>&1

# Synchronisiert Adl-M Csv-Ordner auf dem Windows-Rechner mit seinem Backup auf dem 182-er
30 8 * * * rsync -av /mnt/pc19487/adl-m/csv /media/memory01/ei_data_exploratories/backup/adl-m_programe/ >> /home/eibestations/backup_adlm/error_adlm_csv.log 2>&1

# Synchronisiert vom den Technikern hoch geladenen .dat-Files auf dem 83-er mit dem Backup auf dem 182-er
0 9 * * * rsync -av /mnt/pc19460/incoming_ftp/adl-m /media/memory01/ei_data_exploratories/backup/incoming_ftp/ >> /home/eibestations/backup_adlm/error_ftp_dat_files.log 2>&1

# Synchronisiert vom den Technikern hoch geladene .dat-Files und aus dem ADML-Programm erstellete solche mit dem tsm-Ordner
10 9 * * * bash /home/eibestations/backup_adlm/tsm_sync.bash  >> /home/eibestations/backup_adlm/error_tsm_sync.log 2>&1


