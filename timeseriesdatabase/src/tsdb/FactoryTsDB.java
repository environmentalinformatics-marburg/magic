package tsdb;

import java.io.File;
import java.io.IOException;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import tsdb.aggregated.AggregationType;
import tsdb.util.Util;

/**
 * Factory for TimeSeriesDatabase
 * @author woellauer
 *
 */
public class FactoryTsDB {

	private static final Logger log = Util.log;
	
	final static String CONFIG_DIRECTORY = "config/";

	
	public static TsDB createDefault() {
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
	
	public static TsDB createDefault(String databaseDirectory,String configDirectory, String cacheDirectory) {		
		try {
			TsDB timeSeriesDatabase = new TsDB(databaseDirectory,configDirectory+"eventstore_config.properties", cacheDirectory);
			ConfigLoader configLoader = new ConfigLoader(timeSeriesDatabase);
			
			//*** global config start			
			configLoader.readRegionConfig(configDirectory+"region.ini");
			//*** global config end
			
			//*** BE start
			configLoader.readLoggerSchemaConfig(configDirectory+"station_type_schema.ini"); // BE 2. read schema of logger types and create: logger type objects, sensor objects
			configLoader.readGeneralStationConfig(configDirectory+"general_stations.ini"); // BE 1. read list of general stations and create: general station objects
			configLoader.readStationConfig(configDirectory+"be_config_station_inventory.cnf"); // BE 3. read station list, generate general station name and properties and create station objects
			configLoader.readSensorNameTranslationConfig(configDirectory+"be_config_level0050_standards.cnf"); // BE 4. read read input name sensor translation and insert it in existing logger type objects
			configLoader.readStationGeoPositionConfig(configDirectory+"be_station_master.csv"); // BE read and insert geo position and station serial to station objects, add nearest station list to station object
			//*** BE end
			

			//*** KiLi start
			configLoader.readLoggerSchemaConfig(configDirectory+"station_type_schema_kili.ini"); // KiLi 2. read schema of logger types and create: logger type objects, sensor objects
			configLoader.readGeneralStationConfig(configDirectory+"general_stations_kili.ini"); // KiLi 1. read list of general stations and create: general station objects
			configLoader.readLoggerTypeSensorTranslationConfig(configDirectory+"logger_type_sensor_translation_kili.ini"); // KiLi 3. read read input name sensor translation and insert it in existing logger type objects
			configLoader.readVirtualPlotConfig(configDirectory+"station_master.csv"); // KiLi 4. read plotids and create virtualplot objects    TODO: read and insert geo position
			configLoader.readKiLiStationConfig(configDirectory+"ki_config_station_inventory.cnf"); // KiLi 5. read time interval of stations and insert it in virtualplot objects
			configLoader.calcNearestVirtualPlots();
			//*** KilI end
			
			//*** sensor config	start		
			configLoader.readIgnoreSensorNameConfig(configDirectory+"ignore_sensors.ini"); // read and insert sensor names that should be not inserted in database
			configLoader.readSensorPhysicalRangeConfig(configDirectory+"parameter_physical_range.ini"); // read and insert physical range to sensor objects
			configLoader.readSensorEmpiricalRangeConfig(configDirectory+"parameter_empirical_range.ini"); // (TODO change/remove)  read and insert empirical range to sensor objects
			configLoader.readSensorStepRangeConfig(configDirectory+"parameter_step_range.ini"); // read and insert step range to sensor objects
			configLoader.readBaseAggregationConfig(configDirectory+"base_aggregation.ini"); // read and insert type of aggregation to sensor objects
			configLoader.readInterpolationSensorNameConfig(configDirectory+"interpolation_sensors.ini"); // read list of sensor names for interpolation and mark sensor objects
			configLoader.readEmpiricalDiffConfig(configDirectory+"parameter_empirical_diff.ini"); // (TODO change) read empirical max diff and insert it in sensor objects
			//*** sensor config end
			
			
			//timeSeriesDatabase.readKiLiStationGeoPositionConfig(configDirectory+"station_master.csv");
			
			timeSeriesDatabase.updateGeneralStations(); //TODO later remove!
			
			
			return timeSeriesDatabase;		
		} catch (Exception e) {
			e.printStackTrace();
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