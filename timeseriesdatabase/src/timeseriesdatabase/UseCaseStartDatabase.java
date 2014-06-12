package timeseriesdatabase;

import java.nio.file.Paths;
import java.util.Iterator;

import de.umr.jepc.store.Event;

public class UseCaseStartDatabase {

	public static void main(String[] args) {
		System.out.println("begin...");
		TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase();
		timeSeriesDatabase.readGeneralStationConfig("config/general_station_list.txt");
		timeSeriesDatabase.readLoggerSchemaConfig("config/station_type_schema.ini");
		timeSeriesDatabase.readStationConfig("config/be_config_station_inventory.cnf");
		timeSeriesDatabase.readSensorNameTranslationConfig("config/be_config_level0050_standards.cnf");
		timeSeriesDatabase.readIgnoreSensorNameConfig("config/ignore_sensor_name_list.txt");
		
		//String sql = "SELECT * FROM HEG03 where tstart>=58508670 AND tstart<=58508690";
		String sql = "SELECT * FROM HEG03 where tstart=58508670";
		Iterator<Event> it = timeSeriesDatabase.query(sql);
		while(it.hasNext()) {
			Event next = it.next();
			System.out.println(next);
		}
		
		
		
		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);

	}

}
