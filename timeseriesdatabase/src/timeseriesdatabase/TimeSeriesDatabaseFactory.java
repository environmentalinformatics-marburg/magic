package timeseriesdatabase;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import util.Util;

/**
 * Factory for TimeSeriesDatabase
 * @author Stephan Wöllauer
 *
 */
public class TimeSeriesDatabaseFactory {

	private static final Logger log = Util.log;

	public static TimeSeriesDatabase createDefault() {		
		try {		
			TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase("c:/timeseriesdatabase_database/","config/eventstore_config.properties");
			timeSeriesDatabase.readGeneralStationConfig("config/general_stations.ini");
			timeSeriesDatabase.readLoggerSchemaConfig("config/station_type_schema.ini");
			timeSeriesDatabase.readStationConfig("config/be_config_station_inventory.cnf");
			timeSeriesDatabase.readSensorNameTranslationConfig("config/be_config_level0050_standards.cnf");
			timeSeriesDatabase.readIgnoreSensorNameConfig("config/ignore_sensors.ini");
			timeSeriesDatabase.readSensorRangeConfig("config/parameter_range.ini");
			timeSeriesDatabase.readBaseAggregationConfig("config/base_aggregation.ini");
			timeSeriesDatabase.readStationGeoPositionConfig("config/be_station_master.csv");
			timeSeriesDatabase.readGapFillingConfig("config/gap_filling.ini");		
			return timeSeriesDatabase;		
		} catch (Exception e) {
			log.error("create TimeSeriesDatabase"+e);
			return null;
		}		
	}

}
