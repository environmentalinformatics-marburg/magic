/**
*
* Copyright (C) 2013-2013 Spaska Forteva
* Environmental Informatics
* University of Marburg
* Germany
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*
* Please send any comments, suggestions, criticism, or (for our sake) bug
* reports to sforteva@yahoo.de
*
* http://environmentalinformatics-marburg.de
*/

import java.io.IOException;
import java.net.*;
import java.nio.charset.Charset;
import java.nio.file.*;
import java.io.File;
/**
 * This class transfers csv files local
 * All stations, source and destination directories are written into the configuration file transfer.properties
 * 
 * @version 0.1 2014-05-16
 * @author Spaska Forteva
 *
 */
public class BackupADML_ftp{

	/**
	 * Main method
	 * @param args
	 * @throws IOException 
	 */
	public static void main( String[] args ) throws IOException 
	{
		String []stations = {"HEG", "HEW", "SEG", "SEW", "AEG", "AEW", "JIG", "SET", "AET"};
		try {

 			for ( int s = 0; s < stations.length; s++ ) {
				File file = new File( args[0] + stations[s] );
				String destPathWeekly = args[1] + stations[s];
				String destPathIncoming = args[2] + stations[s];
				File[] files = file.listFiles();
				if (files != null && files.length > 0) {
					for (int i = 0; i < files.length; i++) {
						if (files[i].isFile()) {
							//Kopieren alle Dateien von /mnt/pc19460/incoming_ftp/csv/ in /media/memory01/ei_data_exploratories/backup/incoming_ftp/csv/
							Path copySourcePath = Paths.get( files[i].getAbsolutePath());
							Path copyTargetPathWeekly = Paths.get( destPathWeekly + "/" + files[i].getName() );
							File newfileWeekly = new File( destPathWeekly + "/" + files[i].getName() );
							if (!newfileWeekly.exists()) {
								Files.copy( copySourcePath, copyTargetPathWeekly );
							} else {
								System.out.printf( "backup/incoming_ftp/csv/ '%s' exsistier!",
						       			copySourcePath.getFileName(), Files.size( copySourcePath ) );
								System.out.println();
							}
							//Kopieren alle Dateien von /mnt/pc19460/incoming_ftp/csv/ in /media/memory01/ei_data_exploratories/incoming/
							Path copyTargetPathIncoming = Paths.get( destPathIncoming  + "/" + files[i].getName() );
							File newfileIncoming = new File( destPathIncoming  + "/" + files[i].getName() );
							if (!newfileIncoming.exists()) {
								Files.copy( copySourcePath, copyTargetPathIncoming );
							} else {
								System.out.printf( "/media/memory01/ei_data_exploratories/incoming/'%s' exsistier!",
						       			copySourcePath.getFileName(), Files.size( copySourcePath ) );
								System.out.println();
							}
						}
					}
				}
			}

			
		} catch ( Exception e ) {
			e.printStackTrace();
			System.out.printf( e.toString() );
			System.exit(0);
		}
		
		BackupADML_ftp bcadml = new BackupADML_ftp();
		bcadml.moveToProcessing(args[3], args[0], stations);
	}

	/**
	 * This method moves the files local from to the the given directory
	 * @param destDir
	 * @param scrDir
	 * @param stations HEG HEW SEG SEW AEG AEW AET SET JIG
	 */
	private void moveToProcessing( String destDir, String scrDir, String [] stations )
	{   
		try {
			    for ( String station: stations ) {
					File fileToBeMoved = new File( scrDir + station );
				    	File [] files = fileToBeMoved.listFiles();
					if (files != null && files.length > 0) {
					   	 for ( File file: files ){
							    File newFileName = new File( destDir + station + "/" + file.getName() );
							    File dir = new File(destDir + station);
								if ( !dir.exists()) {
									dir.mkdir();
								}
							    boolean isMoved = file.renameTo(newFileName);
							    if(!isMoved) {
								System.out.printf( "Quelle '%s' ",
							       			file.getAbsolutePath() );
								System.out.printf( "Ziel'%s' ",
							       			newFileName.getAbsolutePath()  );
								System.out.printf( "Datei '%s' wurde nicht verrschoben",
							       			file.getName() );
								System.out.println();
							    } 
							    else {
								System.out.printf( "Datei '%s' ok",
							       			file.getName() );
								}
							   
						}
				    }
			    }
		}
		catch( Exception e) {
			e.printStackTrace();
			System.out.printf( e.toString() );
			System.exit(0);
		}
	}

}
