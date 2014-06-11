package timeseriesdatabase; 

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Scanner;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import au.com.bytecode.opencsv.CSVReader;


public class UseCaseLoadExploratories {
	
	private static final Logger log = LogManager.getLogger("general");
	
	public static void main(String[] args) {
		
		System.out.println("start...");
		
		String config_file = "k:/julendat/julendat/scripts/stations_be/be_config_station_inventory.cnf";
		String logger_config_file =  "k:/julendat/julendat/scripts/stations_be/be_config_level0050_standards.cnf";
		
		Database database = new Database();
		database.configureStations(config_file);
		database.readLoggerConfig(logger_config_file);
		//database.loadDirectoryOfAllExploratories(Paths.get("K:/incoming_ftp/adl-m"));
		database.loadDirectoryOfOneExploratory(Paths.get("K:/HEG_short"));
		database.close();
		
		System.out.println("...end");
		System.exit(0);
	}
	
	

}
