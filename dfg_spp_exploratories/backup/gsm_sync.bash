#!/bin/bash

# Synchronisiert vom den Technikern hoch geladene .dat-Files und aus dem ADML-Programm erstellete solche mit dem tsm-Ordner
# Crontab entry: 10 9 * * * bash /home/eibestations/backup_adlm/gsm_sync.bash  >> /home/eibestations/backup_adlm/error_sync_pc19460_gsm_to_pc19847_gsm.log  2>&1

# PATH fuer source-Ordner
SCR_PATH='/mnt/pc19487/adl-m/download/'

# PATH fuer ziel-Ordner
_PATH='/mnt/pc19460/incoming_gsm/download/'


for n in AEG AEW HEG HEW SEG SEW 
do 
	for i in {1..50} 
	do 
		
		if (( $i < 10 )) 
		then 
			if [ -d ${SCR_PATH}$n\0${i}/backup/ ]
			then
				echo ${SCR_PATH}$n\0${i}
				rsync -av  ${SCR_PATH}$n\0$i/backup/ ${_PATH}$n\0$i/backup/
			fi
			else  
				if [ -d ${SCR_PATH}$n\${i}/backup/ ]
				
				then
					echo File ${SCR_PATH}$n\${i}
					rsync -av  ${SCR_PATH}$n$i/backup/  ${_PATH}$n$i/backup/

				fi
		fi
	done 
done
