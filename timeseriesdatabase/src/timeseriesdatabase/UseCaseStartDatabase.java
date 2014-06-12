package timeseriesdatabase;

import java.nio.file.Paths;
import java.util.Iterator;

import de.umr.eventstore.Stream;
import de.umr.eventstore.processors.ConsoleProcessor;
import de.umr.eventstore.processors.ProcessingEngine;
import de.umr.eventstore.queries.Query;
import de.umr.eventstore.queries.SQLQuery;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

public class UseCaseStartDatabase {

	public static void main(String[] args) {
		System.out.println("begin...");
		TimeSeriesDatabase timeSeriesDatabase = new TimeSeriesDatabase("./database/","config/eventstore_config.properties");
		timeSeriesDatabase.readGeneralStationConfig("config/general_station_list.txt");
		timeSeriesDatabase.readLoggerSchemaConfig("config/station_type_schema.ini");
		timeSeriesDatabase.readStationConfig("config/be_config_station_inventory.cnf");
		timeSeriesDatabase.readSensorNameTranslationConfig("config/be_config_level0050_standards.cnf");
		timeSeriesDatabase.readIgnoreSensorNameConfig("config/ignore_sensor_name_list.txt");
		
		
	
		String sql = "SELECT Ta_10, Ts_10 FROM HEG03 WHERE tstart>=58508670 AND tstart<=58508690";
		//String sql = "SELECT Ta_10, Ts_10 FROM HEG03 WHERE tstart=58508670";
		System.out.println("\n"+sql);
		
		Stream stream = timeSeriesDatabase.store.getStream("HEG03");
		ProcessingEngine engine = new ProcessingEngine(stream);
        engine.appendProcessor(new ConsoleProcessor());
        /* Create an SQL query */
        Query query = new SQLQuery(sql);

        /* Query the stream with the processing engine */
        engine.processQuery(query);
		
		
		
		
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
