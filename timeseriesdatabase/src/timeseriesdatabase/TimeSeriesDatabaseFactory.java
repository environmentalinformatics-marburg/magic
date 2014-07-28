package timeseriesdatabase;

import java.io.File;
import java.io.IOException;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import timeseriesdatabase.aggregated.AggregationType;
import util.Util;

/**
 * Factory for TimeSeriesDatabase
 * @author woellauer
 *
 */
public class TimeSeriesDatabaseFactory {

	private static final Logger log = Util.log;
	
	final static String CONFIG_DIRECTORY = "config/";

	
	public static TimeSeriesDatabase createDefault() {
		System.out.println("JVM bits: "+System.getProperty("sun.arch.data.model"));
		String DATABASE_DIRECTORY = "c:/timeseriesdatabase_database/";
		
		String CACHE_DIRECTORY = "c:/timeseriesdatabase_cache/";
		
		try {
			Wini ini = new Wini(new File(CONFIG_DIRECTORY+"database_paths.ini"));
			Section section = ini.get("database_paths");
			Map<String, String> pathMap = Util.readIniSectionMap(section);
			if(pathMap.containsKey("DATABASE_DIRECTORY")) {
				DATABASE_DIRECTORY = pathMap.get("DATABASE_DIRECTORY");
			}
			if(pathMap.containsKey("CACHE_DIRECTORY")) {
				CACHE_DIRECTORY = pathMap.get("CACHE_DIRECTORY");
			}
		} catch (IOException e) {
			e.printStackTrace();
		}		
		
		return createDefault(DATABASE_DIRECTORY,CONFIG_DIRECTORY,CACHE_DIRECTORY);
	}
	
	public static TimeSeriesDatabase createDefault(String databaseDirectory,String configDirectory, String cacheDirectory) {		
		try {
			TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase(databaseDirectory,configDirectory+"eventstore_config.properties", cacheDirectory);
			
			//BE
			
			timeSeriesDatabase.readGeneralStationConfig(configDirectory+"general_stations.ini");
			timeSeriesDatabase.readLoggerSchemaConfig(configDirectory+"station_type_schema.ini");
			timeSeriesDatabase.readStationConfig(configDirectory+"be_config_station_inventory.cnf");
			timeSeriesDatabase.readSensorNameTranslationConfig(configDirectory+"be_config_level0050_standards.cnf");
			timeSeriesDatabase.readIgnoreSensorNameConfig(configDirectory+"ignore_sensors.ini");
			timeSeriesDatabase.readSensorPhysicalRangeConfig(configDirectory+"parameter_physical_range.ini");
			timeSeriesDatabase.readSensorEmpiricalRangeConfig(configDirectory+"parameter_empirical_range.ini");
			timeSeriesDatabase.readSensorStepRangeConfig(configDirectory+"parameter_step_range.ini");
			timeSeriesDatabase.readBaseAggregationConfig(configDirectory+"base_aggregation.ini");
			timeSeriesDatabase.readStationGeoPositionConfig(configDirectory+"be_station_master.csv");
			timeSeriesDatabase.readInterpolationSensorNameConfig(configDirectory+"interpolation_sensors.ini");
			timeSeriesDatabase.readEmpiricalDiffConfig(configDirectory+"parameter_empirical_diff.ini");
			
			//KiLi
			
			timeSeriesDatabase.readGeneralStationConfig(configDirectory+"general_stations_kili.ini");
			timeSeriesDatabase.readLoggerSchemaConfig(configDirectory+"station_type_schema_kili.ini");
			
			
			
			//timeSeriesDatabase.readKiLiStationGeoPositionConfig(configDirectory+"station_master.csv");
			//timeSeriesDatabase.readKiLiStationConfig(configDirectory+"ki_config_station_inventory.cnf");
			
			
			
			return timeSeriesDatabase;		
		} catch (Exception e) {
			log.error("create TimeSeriesDatabase"+e);
			return null;
		}		
	}
	
	private static void read_database_paths(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("database_paths");
			if(section!=null) {
				for(String pathName:section.keySet()) {
					System.out.println("pathName: "+pathName);
				}
			}
		} catch (IOException e) {
			log.warn(e);
		}		
	}
	
	public static String get_CSV_output_path() {		
		String CSV_OUTPUT_DIRECTORY = "C:/timeseriesdatabase_output/";		
		try {
			Wini ini = new Wini(new File(CONFIG_DIRECTORY+"database_paths.ini"));
			Section section = ini.get("database_paths");
			Map<String, String> pathMap = Util.readIniSectionMap(section);
			if(pathMap.containsKey("CSV_OUTPUT_DIRECTORY")) {
				CSV_OUTPUT_DIRECTORY = pathMap.get("CSV_OUTPUT_DIRECTORY");
				System.out.println("set CSV_OUTPUT_DIRECTORY: "+ CSV_OUTPUT_DIRECTORY);
			} else {
				System.out.println("not found CSV_OUTPUT_DIRECTORY");
			}
		} catch (IOException e) {
			e.printStackTrace();
		}		
		return CSV_OUTPUT_DIRECTORY;
	}

}
