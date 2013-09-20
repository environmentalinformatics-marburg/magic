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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;


/**
* This class provides basic configuration for the local transfer.
*
* @version 0.1 2013-08-28
* @autor sforteva
*/
public class ConfigTransverLocal {

	private static ConfigTransverLocal instance=null;
	private Properties prop;

	private ConfigTransverLocal()
	{
		prop=new Properties();
		File input=new File("transfer.properties");
		if (input.isFile()) {
			try{
				prop.load(new FileInputStream(input));
			} catch (FileNotFoundException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}

	public static ConfigTransverLocal getInstance()
	{
		if (instance==null){
			instance=new ConfigTransverLocal();
		}
		return instance;
	}

	public ConfigTransverLocal clone()
	{
		return ConfigTransverLocal.getInstance();
	}

	public String get(String key,String defaultValue)
	{
		return prop.getProperty(key, defaultValue);
	}

	public String get(String key)
	{
		return get(key,null);
	}


}