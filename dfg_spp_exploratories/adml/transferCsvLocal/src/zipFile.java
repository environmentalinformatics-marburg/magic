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

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.zip.GZIPOutputStream;

/**
 * This class zippen files
 * 
 * @version 0.1 2013-09-19
 * @author Spaska Forteva
 * 
 */
public class zipFile {
	private static final int BLOCKSIZE = 8192;
	public static boolean zip( String arg ) 
	{   
		boolean res = true;
		if ( arg.length() == 0 ){
			System.out.println( "Usage: gzip source" );
			return false;
		}
		GZIPOutputStream gzos = null;
		FileInputStream  fis  = null;
		try{
			gzos = new GZIPOutputStream( new FileOutputStream( arg + ".gz" ) );
			fis  = new FileInputStream( arg );
			byte[] buffer = new byte[ BLOCKSIZE ];
			for ( int length; (length = fis.read(buffer, 0, BLOCKSIZE)) != -1; )
				gzos.write( buffer, 0, length );
		}
		catch ( IOException e ){
			res = false;
			System.err.println( "Error: Couldn't compress " + arg );
		}
		finally {
			if ( fis != null )
				try { fis.close(); } catch ( IOException e ) { e.printStackTrace(); }
			if ( gzos != null )
				try { gzos.close(); } catch ( IOException e ) { e.printStackTrace(); }
		}
		return res;
	}
}
