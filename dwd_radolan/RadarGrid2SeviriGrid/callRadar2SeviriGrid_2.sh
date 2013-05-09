#! /bin/sh

rm -rf Radar2SeviriGrid.x
gfortran Radar2SeviriGrid.f90 -o Radar2SeviriGrid.x


 chInputPath="/media/PRECI/Daten_Radar/radolan_rst_RGrid/2010/"
 chOutputPath="/media/PRECI/Daten_Radar/radolan_rst_SGrid/"
 echo "chInputPath: " $chInputPath

#if [ -e radar2.dat ]; then
#rm radar2.dat
#fi
#touch radar2.dat



# find $chInputPath -name 2*.rst | sort >> radar2.dat

 cat radar2.dat | while read line;do
   DIRECTORY=`dirname $line`
   length="${#DIRECTORY}"
   a=2
   b=13
   chDateStart=$((length+a))
   chDateEnd=$((length+b))
   # date
   chDate=`echo ${line} |cut -c$chDateStart-$chDateEnd`
   echo "file:" $line " date:" $chDate

  ./Radar2SeviriGrid.x $line $chDate

   echo '****************************************'


   year=`echo ${chDate} |cut -c1-4`
   month=`echo ${chDate} |cut -c5-6`
   day=`echo ${chDate} |cut -c7-8`
   hh=`echo ${chDate} |cut -c9-10`
   mi=`echo ${chDate} |cut -c11-12`

#### sortieren ####

   # Anlegen der nötigen Ordner wenn sie noch nicht existieren
   if [ ! -d "$chOutputPath""$year" ]
    then
    mkdir "$chOutputPath""$year"
    chmod g+w "$chOutputPath""$year"
   fi

   if [ ! -d "$chOutputPath""$year"/"$month" ]
    then
    mkdir "$chOutputPath""$year"/"$month"
    chmod g+w "$chOutputPath""$year"/"$month"
   fi 
  
   if [ ! -d "$chOutputPath""$year"/"$month"/"$day" ]
    then
    mkdir "$chOutputPath""$year"/"$month"/"$day"
    chmod g+w "$chOutputPath""$year"/"$month"/"$day"
   fi

  chOutputPathFinal="$chOutputPath""$year"/"$month"/"$day" 	  
  echo "outputPath :" $chOutputPathFinal
  mv *"$chDate"* "$chOutputPathFinal"

 done



echo "Radar2SeviriGrid.f90 finished!"


