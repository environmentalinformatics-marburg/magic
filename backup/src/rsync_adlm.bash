#!/bin/bash

# -a fasst folgende Optionen zusammen: 
# -r kopiert Unterverzeichnisse 
# -l kopiert symbolische Links 
# -p behält Rechte der Quelldatei bei 
# -t behält Zeiten der Quelldatei bei, 
# -g behält Gruppenrechte der Quelldatei bei 
# -o behält Besitzrechte der Quelldatei bei (nur root) 
# -D behält Gerätedateien der Quelldatei bei (nur root)

rsync -av /mnt/pc19487/adl-m/download /media/memory01/ei_data_exploratories/backup/incoming_gsm/adl-m/ >> error_adlm_download.log 2>&1 & 
rsync -av /mnt/pc19487/adl-m/settings /media/memory01/ei_data_exploratories/backup/adl-m_programe/ >> error_adlm_settings.log 2>&1 & 
rsync -av /mnt/pc19487/adl-m/csv /media/memory01/ei_data_exploratories/backup/adl-m_programe/ >> error_adlm_csv.log 2>&1


# Kopiert vom 145-er aus dem programm die .dat - Files und von 83 alle vom den Technikern hoch geladenen .dat-Files in backup

rsync -av /mnt/pc19460/incoming_ftp/adl-m /media/memory01/ei_data_exploratories/backup/incoming_ftp/ >> error_ftp_dat_files.log 2>&1
