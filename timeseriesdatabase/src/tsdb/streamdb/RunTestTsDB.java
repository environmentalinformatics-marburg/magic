package tsdb.streamdb;
import java.util.Iterator;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import de.umr.jepc.store.Event;


public class RunTestTsDB {
	
	public static void main(String[] args) {
		long time_start = System.currentTimeMillis();
		TsDB tsdb = TsDBFactory.createDefault();
		

		
		long total_value_count = 0;
		long total_sensor_count = 0;
		for(String stationName:tsdb.getStationNames()) {
			long station_value_count = 0;
			Iterator<Event> it = tsdb.streamStorage.queryRawEvents(stationName, null, null);
			if(it!=null) {
				while(it.hasNext()) {
					it.next();
				}
			}
			total_value_count += station_value_count;
			System.out.println(stationName+" station_value_count "+station_value_count);
		}
		System.out.println("total_sensor_count "+total_sensor_count);
		System.out.println("total_value_count "+total_value_count);
		
		
		
		
		tsdb.close();
		long time_end = System.currentTimeMillis();
		System.out.println(((time_end-time_start)/1000)+" s");
	}	

}
