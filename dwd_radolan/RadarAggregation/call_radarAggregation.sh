#! /bin/sh

rm -rf radarAggregation.x
gfortran radarAggregation.f90 -o radarAggregation.x


 chInputPath="/media/PRECI/Daten_Radar/radolan_rst_SGrid/2010/"
 chOutputPath="/media/PRECI/Daten_Radar/radolan_rst_SGrid_daily/"
 echo "chInputPath: " $chInputPath



### create scenens.dat
if [ -e scenes.dat ]; then
rm scenes.dat
fi
touch scenes.dat

if [ -e temp.dat ]; then
rm temp.dat
fi
touch temp.dat

find $chInputPath -name 20*_radolan_SGrid.rst | sort >> temp.dat

 cat temp.dat | while read line;do
   DIRECTORY=`dirname $line`
   length="${#DIRECTORY}"
   a=2
   b=13
   chDateStart=$((length+a))
   chDateEnd=$((length+b))
   # date
   chDate=`echo ${line} |cut -c$chDateStart-$chDateEnd`
   #echo "file:" $line " date:" $chDate
   echo $chDate >> scenes.dat
 done


### call

if [ -e input.dat ]; then
rm input.dat
fi
touch input.dat

 find $chInputPath -name 20*0050_radolan_SGrid.rst | sort >> input.dat

 cat input.dat | while read line;do
   DIRECTORY=`dirname $line`
   length="${#DIRECTORY}"
 
   b=2
   chDateStart=$((length-length+1))
   chDateEnd=$((length-b))
   # date
   chPath=$DIRECTORY"/"
   echo "path:" $DIRECTORY

   a=2
   b=13
   chDateStart=$((length+a))
   chDateEnd=$((length+b))
   # date
   chDate=`echo ${line} |cut -c$chDateStart-$chDateEnd`
   echo "path:" $chPath " date:" $chDate

 ./radarAggregation.x $chDate "$chPath"  250 170

   #echo '****************************************'

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
  

  chOutputPathFinal="$chOutputPath""$year"/"$month" 	  
  #echo "outputPath :" $chOutputPathFinal
  mv *"$year$month$day"* "$chOutputPathFinal"

 done



echo "satAggregation.x.f90 finished!"


