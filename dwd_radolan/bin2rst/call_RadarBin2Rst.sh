#!/bin/sh

inputDirectory="/media/PRECI/Daten_Radar/2010/"
outputDirectory="/media/PRECI/Daten_Radar/radolan_rst_RGrid/"

rm -rf RadarBin2Rst.x
gfortran -fno-range-check RadarBin2Rst.f90 -o RadarBin2Rst.x

 if [ -e temp.dat ]; then
 rm temp.dat
 fi
 touch temp.dat


 find "$inputDirectory" -name raa01-rw_10000-10*bin | sort >> temp.dat
 cat temp.dat | while read line;do
   
   #echo $line
   chInputFile=$line
   echo "chInputFile:" $chInputFile
   chDirectory=`dirname $line`
   LENDIR="${#chDirectory}"

   # date
   a2=17
   a13=26
   chDateStart=$((LENDIR+a2))
   chDateEnd=$((LENDIR+a13))
   chInputDate=`echo ${line} |cut -c$chDateStart-$chDateEnd`
   echo "chInputDate:" $chInputDate

   year2=`echo ${chInputDate} |cut -c1-2`
   month=`echo ${chInputDate} |cut -c3-4`
   day=`echo ${chInputDate} |cut -c5-6`
   hh=`echo ${chInputDate} |cut -c7-8`
   mi=`echo ${chInputDate} |cut -c9-10`
   year="20"$year2
   chInputDateNew="$year""$month""$day""$hh""$mi"
   echo "chInputDateNew:" $chInputDateNew

   ./RadarBin2Rst.x $chInputFile $chInputDateNew 


#### sortieren ####

   # Anlegen der nötigen Ordner wenn sie noch nicht existieren
   if [ ! -d "$outputDirectory""$year" ]
    then
    mkdir "$outputDirectory""$year"
    chmod g+w "$outputDirectory""$year"
   fi

   if [ ! -d "$outputDirectory""$year"/"$month" ]
    then
    mkdir "$outputDirectory""$year"/"$month"
    chmod g+w "$outputDirectory""$year"/"$month"
   fi 
  
   if [ ! -d "$outputDirectory""$year"/"$month"/"$day" ]
    then
    mkdir "$outputDirectory""$year"/"$month"/"$day"
    chmod g+w "$outputDirectory""$year"/"$month"/"$day"
   fi

  ouputPath="$outputDirectory""$year"/"$month"/"$day" 	  
  echo "outputPath :" $ouputPath
  mv *"$chInputDateNew"* "$ouputPath"


done

