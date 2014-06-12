package timeseriesdatabase;

import java.nio.file.Paths;

public class UseCaseInitDatabaes {

	public static void main(String[] args) {
		System.out.println("begin...");
		
		TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase("./database/","config/eventstore_config.properties");
		timeSeriesDatabase.clear();
		timeSeriesDatabase.readGeneralStationConfig("config/general_station_list.txt");
		timeSeriesDatabase.readLoggerSchemaConfig("config/station_type_schema.ini");
		timeSeriesDatabase.readStationConfig("config/be_config_station_inventory.cnf");
		timeSeriesDatabase.readSensorNameTranslationConfig("config/be_config_level0050_standards.cnf");
		timeSeriesDatabase.readIgnoreSensorNameConfig("config/ignore_sensor_name_list.txt");
		timeSeriesDatabase.registerStreams();
		
		//timeSeriesDatabase.loadDirectoryOfOneExploratory(Paths.get("K:/HEG_short"));
		timeSeriesDatabase.loadDirectoryOfAllExploratories(Paths.get("K:/incoming_ftp/adl-m"));
		
		
		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
