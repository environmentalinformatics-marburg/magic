package timeseriesdatabase;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Factory for TimeSeriesDatabase
 * @author Stephan Wöllauer
 *
 */
public class TimeSeriesDatabaseFactory {
	
	private static final Logger log = Util.log;
	
	public static TimeSeriesDatabase createDefault() {
		
		try {
		
		//TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase("./database/","config/eventstore_config.properties");
		TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase("c:/timeseriesdatabase_database/","config/eventstore_config.properties");
		timeSeriesDatabase.readGeneralStationConfig("config/general_station_list.txt");
		timeSeriesDatabase.readLoggerSchemaConfig("config/station_type_schema.ini");
		timeSeriesDatabase.readStationConfig("config/be_config_station_inventory.cnf");
		timeSeriesDatabase.readSensorNameTranslationConfig("config/be_config_level0050_standards.cnf");
		timeSeriesDatabase.readIgnoreSensorNameConfig("config/ignore_sensor_name_list.txt");
		timeSeriesDatabase.readSensorRangeConfig("config/sensor_range_config.ini");
		
		return timeSeriesDatabase;
		
		} catch (Exception e) {
			log.error("create TimeSeriesDatabase"+e);
			return null;
		}
		
		
	}

}
