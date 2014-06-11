package timeseriesdatabase; 

import java.util.Iterator;

import de.umr.jepc.store.Event;


public class UseCaseQuery {
	
	public static void main(String[] args) {
		
		System.out.println("start...");
		
		String config_file = "k:/julendat/julendat/scripts/stations_be/be_config_station_inventory.cnf";
		Database database = new Database();
		database.configureStations(config_file);
		
		Storage storage = database.getStorage();
		
		Iterator<Event> it = storage.query("SELECT * FROM HEG03__LT_10_MAX WHERE a>10 AND tstart<58217520");
		//Iterator<Event> it = storage.queryTimeSeries("HEG03__LT_10_MAX",58217520,58218240);
		while(it.hasNext()) {
			Event e = it.next();
			System.out.println(e);
		}
		
		
		database.close();
		
		System.out.println("...end");
		System.exit(0);
	}

}
