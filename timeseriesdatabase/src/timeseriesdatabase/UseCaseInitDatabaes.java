package timeseriesdatabase;

import java.nio.file.Paths;

public class UseCaseInitDatabaes {

	public static void main(String[] args) {
		System.out.println("begin...");
		TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase();
		timeSeriesDatabase.readGeneralStationConfig("config/general_station_list.txt");
		timeSeriesDatabase.readLoggerSchemaConfig("config/station_type_schema.ini");
		timeSeriesDatabase.readStationConfig("config/be_config_station_inventory.cnf");
		timeSeriesDatabase.readSensorNameTranslationConfig("config/be_config_level0050_standards.cnf");
		timeSeriesDatabase.registerStreams();
		
		timeSeriesDatabase.loadDirectoryOfOneExploratory(Paths.get("K:/HEG_short"));		
		
		
		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
