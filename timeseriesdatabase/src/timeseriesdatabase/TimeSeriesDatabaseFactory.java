package timeseriesdatabase;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import util.Util;

/**
 * Factory for TimeSeriesDatabase
 * @author woellauer
 *
 */
public class TimeSeriesDatabaseFactory {

	private static final Logger log = Util.log;

	
	public static TimeSeriesDatabase createDefault() {
		final String DATABASE_DIRECTORY = "c:/timeseriesdatabase_database/";
		final String CONFIG_DIRECTORY = "config/";
		final String CACHE_DIRECTORY = "c:/timeseriesdatabase_cache/";
		return createDefault(DATABASE_DIRECTORY,CONFIG_DIRECTORY,CACHE_DIRECTORY);
	}
	
	public static TimeSeriesDatabase createDefault(String databaseDirectory,String configDirectory, String cacheDirectory) {		
		try {
			TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase(databaseDirectory,configDirectory+"eventstore_config.properties", cacheDirectory);
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
			return timeSeriesDatabase;		
		} catch (Exception e) {
			log.error("create TimeSeriesDatabase"+e);
			return null;
		}		
	}

}
