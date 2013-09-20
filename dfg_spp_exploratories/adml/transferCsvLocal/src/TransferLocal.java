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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintStream;
import java.io.Reader;
import java.text.DateFormat;
import java.util.Calendar;
import java.nio.charset.Charset;


/**
 * This class transfers csv files local
 * All stations, source and destination directories are written into the configuration file transfer.properties
 * 
 * @version 0.1 2013-09-19
 * @author Spaska Forteva
 *
 */
public class TransferLocal{

	/**
	 * Main method
	 * @param args
	 * @throws IOException 
	 */
	public static void main( String[] args ) throws IOException 
	{
		ConfigTransverLocal conf = ConfigTransverLocal.getInstance();
		try {
			PrintStream errstr;
			// Writing in error file
			errstr = new PrintStream( new FileOutputStream( conf.get( "scrPath" )+"error.log",true ));
			String today="=============================================================================\n"+DateFormat.getDateTimeInstance( DateFormat.LONG,DateFormat.FULL).format( Calendar.getInstance().getTime())+"\n\n";
			errstr.write( today.getBytes(),0,today.length());
			System.setErr( errstr );
			String gebiete = conf.get( "stations" );
			args =  gebiete.split(" ");
			/*File dir = new File( "C:/ADL-M/download/" );
			if (!dir.exists()) {
				System.out.println("No exist");
			}
			if ( zipFile.zip( "C:/ADL-M/download/")) {
	
			}*/
			for ( int i = 0; i< args.length; i++ ) {
				TransferLocal myobj = new TransferLocal();
		        String confgStations = conf.get( args[i]);
				String[] stations = confgStations.split( " ");
				for (  int j = 0; j< stations.length; j++) {
					myobj.createNewFile( stations[j], conf);
				}
			 }
		} catch ( Exception e) {
			e.printStackTrace();
		}
	}


	/**
	 * This function create a new file. 
	 * The file name contents the start and end date time from the content
	 * At the beginning will be added 11 rows header
	 * @param param parameters as string presentation 
	 * @param conf configuration from the properties file
	 */
	public void createNewFile( String param,  ConfigTransverLocal conf )
	{
		FileOutputStream fos = null;
		FileInputStream  fis = null;
		int headerRowsNumber = 0;
		String name = param;
		String scrPath = conf.get( "scrPath");
		String stationName = name.substring( 0,3 );
		File dir = new File( conf.get( "destPath" ) + stationName );
		if ( !dir.exists()) {
			dir.mkdir();
		} 

		scrPath  = scrPath  + name + "/csv/" + name + ".csv";
		File srcFile = new File( scrPath );
		if( conf.get( "headerRowsNumber" ) != "" ) {
			headerRowsNumber = Integer.parseInt( conf.get( "headerRowsNumber" ) );
		}
		try{
			fis = new FileInputStream( srcFile );
			Reader reader = null;
			String startDate = "";
			String endDate = "";
			BufferedReader br = new BufferedReader( new InputStreamReader( fis, Charset.forName( "UTF-8" ) ) );
			try{
				reader = new FileReader( srcFile );
				int index = 0;
				String  line = "";

				// extracts the start and the end date
				while ( ( line = br.readLine() ) != null ) {
					index++;
					endDate= line;
					if ( index == 3 ){
						startDate = this.formatDateTime( endDate );		        	 
					}
				}
				endDate = formatDateTime( endDate );
			}

			catch ( IOException e ){
				System.err.println(  "Fehler beim Lesen der Datei!" );
				e.printStackTrace();
			}
			catch ( Exception e1 ){
				e1.printStackTrace();
			}
			finally{
				try { reader.close(); } catch ( Exception e ) { }
			}
			fos = new FileOutputStream( dir + "/" + name + "_" +  startDate + "_" + endDate + ".csv", true );

			// Writing the header
			for ( int i = 0; i < headerRowsNumber; i++ ){
				String headerRow = conf.get( "header" +i );
				String n = "\n";
				byte[] newRow = n.getBytes();
				byte[] row = headerRow.getBytes();

				fos.write( row );
				fos.write( newRow );
			}

			fis.close();
			fos.close();
			fos = new FileOutputStream( dir + "/" + name + "_" + startDate + "_" + endDate + ".csv" , true );
			fis = new FileInputStream( srcFile );
			this.copy(  fis, fos );
			fis.close();
			fos.close();

		}catch ( IOException e ){
			e.printStackTrace();
		}  
		finally{
			if ( fis != null )
				try{ fis.close(); } catch ( IOException e ) { }
			if ( fos != null )
				try{ fos.close(); } catch ( IOException e ) { e.printStackTrace(); }
		}
	}

	/**
	 * Formats the given date time 
	 * @param String input date time
	 * @return String format date time
	 */
	public String formatDateTime( String d )
	{
		String res = "";
		res = ( d.split( ";" ) )[0];
		res = res.replace( ".", "-" );
		res = res.replace( " ", "_" );
		res = res.replace( ":", "" );
		return res;
	}

	/**
	 * Copy the content from the given input into the given output stream 
	 * @param in input stream
	 * @param out output stream
	 * @throws IOException
	 */
	public void copy( InputStream in, OutputStream out ) throws IOException 
	{
		byte[] buffer = new byte[ 0xFFFF ];

		for ( int len; ( len = in.read( buffer ) ) !=-1; )
			out.write( buffer, 0, len );
	}

}