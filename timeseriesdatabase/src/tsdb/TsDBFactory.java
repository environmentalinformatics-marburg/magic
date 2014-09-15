package tsdb;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Map;

import org.ini4j.Profile.Section;
import org.ini4j.Wini;

import tsdb.util.TsDBLogger;
import tsdb.util.Util;

/**
 * Factory for TimeSeriesDatabase
 * @author woellauer
 *
 */
public class TsDBFactory implements TsDBLogger {
	
	static String CONFIG_DIRECTORY = "config/";
	static String DATABASE_DIRECTORY = "c:/timeseriesdatabase_database/";
	static String CACHE_DIRECTORY = "c:/timeseriesdatabase_cache/";
	
	public static String SOURCE_BE_STRUCTURE_ONE_PATH = "c:/timeseriesdatabase_data_source_structure_one";
	public static String SOURCE_BE_STRUCTURE_TWO_PATH = "c:/timeseriesdatabase_data_source_structure_two";
	public static String SOURCE_KILI_PATH = "c:/timeseriesdatabase_data_source_structure_kili/";
	public static String SOURCE_KILI_TFI_PATH = "c:/timeseriesdatabase_data_source_structure_kili_tfi";
	
	public static TsDB createDefault() {
		//System.out.println("JVM bits: "+System.getProperty("sun.arch.data.model"));		
		
		
		try {
			Wini ini;
			if(Files.exists(Paths.get("database_paths.ini"))) {
				System.out.println("read from root: database_paths.ini");
				ini = new Wini(new File("database_paths.ini"));
			} else {
				System.out.println("read from config: database_paths.ini");
				ini = new Wini(new File(CONFIG_DIRECTORY+"database_paths.ini"));
			}			
			Section section = ini.get("database_paths");
			Map<String, String> pathMap = Util.readIniSectionMap(section);
			if(pathMap.containsKey("DATABASE_DIRECTORY")) {
				DATABASE_DIRECTORY = pathMap.get("DATABASE_DIRECTORY");
			}
			if(pathMap.containsKey("CACHE_DIRECTORY")) {
				CACHE_DIRECTORY = pathMap.get("CACHE_DIRECTORY");
			}
			if(pathMap.containsKey("SOURCE_BE_STRUCTURE_ONE_PATH")) {
				SOURCE_BE_STRUCTURE_ONE_PATH = pathMap.get("SOURCE_BE_STRUCTURE_ONE_PATH");
			}
			if(pathMap.containsKey("SOURCE_BE_STRUCTURE_TWO_PATH")) {
				SOURCE_BE_STRUCTURE_TWO_PATH = pathMap.get("SOURCE_BE_STRUCTURE_TWO_PATH");
			}
			if(pathMap.containsKey("SOURCE_KILI_PATH")) {
				SOURCE_KILI_PATH = pathMap.get("SOURCE_KILI_PATH");
			}
			if(pathMap.containsKey("SOURCE_KILI_TFI_PATH")) {
				SOURCE_KILI_TFI_PATH = pathMap.get("SOURCE_KILI_TFI_PATH");
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
			configLoader.readSensorStepRangeConfig(configDirectory+"parameter_step_range.ini"); // read and insert step range to sensor objects
			configLoader.readBaseAggregationConfig(configDirectory+"base_aggregation.ini"); // read and insert type of aggregation to sensor objects
			configLoader.readInterpolationSensorNameConfig(configDirectory+"interpolation_sensors.ini"); // read list of sensor names for interpolation and mark sensor objects
			configLoader.readEmpiricalDiffConfig(configDirectory+"parameter_empirical_diff.ini"); // (TODO change) read empirical max diff and insert it in sensor objects
			//*** sensor config end
			
			//*** global config start
			configLoader.readSensorDescriptionConfig(configDirectory+"sensor_description.ini");
			configLoader.readSensorUnitConfig(configDirectory+"sensor_unit.ini");
			//*** global config end
			
			//timeSeriesDatabase.readKiLiStationGeoPositionConfig(configDirectory+"station_master.csv");
			
			timeSeriesDatabase.updateGeneralStations(); //TODO later remove!
			
			
			return timeSeriesDatabase;		
		} catch (Exception e) {
			e.printStackTrace();
			log.error("create TimeSeriesDatabase"+e);
			return null;
		}		
	}
	
	/*private static void read_database_paths(String configFile) {
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
	}*/
	
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
