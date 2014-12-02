#!/bin/bash

# PATH fuer gsm-Ordner
GSM_PATH='/mnt/pc19487/adl-m/download/'

# PATH fuer ftp-Ordner
FTP_PATH='/mnt/pc19460/incoming_ftp/adl-m/'

# PATH fuer tsm-Ordner
TSM_PATH='/media/memory01/ei_data_exploratories/tsm/'

for n in AEG AEW HEG HEW SEG SEW
do 
for i in {1..50} 
do 

	if (( $i < 10 )) 
	then 
		if [ -d ${GSM_PATH}$n\0${i}/backup/ ]
		then
			echo "GSM ${GSM_PATH}$n\0${i}/backup/"
			rsync -av  ${GSM_PATH}$n\0$i/backup/*.dat  ${TSM_PATH}$n\0${i}/
        	fi 
		echo "FTP ${FTP_PATH}$n/$n\0${i}"
		if [ -d ${FTP_PATH}$n/$n\0${i}/ ]
		then
			rsync -av  ${FTP_PATH}$n/$n\0$i/*.dat  ${TSM_PATH}$n\0${i}/
		fi
	else  
		
		if [ -d ${GSM_PATH}$n${i}/backup/ ]
		then
			echo "GSM ${GSM_PATH}$n${i}/backup/"
			rsync -av  ${GSM_PATH}$n$i/backup/*.dat  ${TSM_PATH}$n${i}/
		fi 
		echo "FTP ${FTP_PATH}$n/$n${i}"
		if [ -d ${FTP_PATH}$n/$n${i} ]
		then
			rsync -av  ${FTP_PATH}$n/$n${i}/*.dat  ${TSM_PATH}$n${i}/
		fi
	fi
done 
done

