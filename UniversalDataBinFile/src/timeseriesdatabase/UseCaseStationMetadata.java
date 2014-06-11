package timeseriesdatabase;

import java.util.Map;

public class UseCaseStationMetadata {
	
	public static void main(String[] args) {
		System.out.println("start...");
		String station_config_file = "k:/julendat/julendat/scripts/stations_be/be_config_station_inventory.cnf";
		String logger_config_file =  "k:/julendat/julendat/scripts/stations_be/be_config_level0050_standards.cnf";
		
		
		
		
		
		Database database = new Database();
		database.configureStations(station_config_file);
		database.readLoggerConfig(logger_config_file);
		
		Storage storage = database.getStorage();
		
		//System.out.println(storage.getStreamIDs());
		
		
		/*for(String key:database.getStations().keySet()) {
			System.out.println(key);
		}*/
		
		Station station = database.getStation("HEG02");
		System.out.println(station.getProperies());
		
		Map<String, Sensor> sensorMap = station.getSensorMap();
		
		System.out.println(sensorMap.keySet());
		
		
		database.close();
		System.out.println("...end");	
		System.exit(0);
		
	}
}
