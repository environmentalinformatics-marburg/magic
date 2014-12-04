#!/bin/bash


while true
do
  echo "Directory into them double files will be deleted:"
  read directory1
  if [ -d $directory1 ]; then
    break
  else
    echo "Invalid directory"
  fi
done

while true
do
  echo "Directory to compare:"
  read directory2
  if [ -d $directory2 ]; then
    break
  else
    echo "Invalid directory"
  fi
done

for FILE in `find  $directory2 -type f `
do
  h=`md5sum $FILE | awk '{ print $1 }'`
  f1=${FILE##*/}

  for f in `find  $directory1 -type f `
  do
    	f2=${f##*/}
	if [ "$f1" = "$f2" ]; then

		s=`md5sum $f | awk '{ print $1 }'`
		if [ "$h" = "$s" ]; then
			echo Removing $f
			#rm -rf $f
		fi
        		
			
	fi
    
  done
done
