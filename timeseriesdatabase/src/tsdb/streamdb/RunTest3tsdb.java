package tsdb.streamdb;
import java.util.ArrayList;
import java.util.Iterator;

import de.umr.jepc.store.Event;
import tsdb.TsDB;
import tsdb.TsDBFactory;


public class RunTest3tsdb {

	public static void main(String[] args) {
		long time_start = System.currentTimeMillis();
		TsDB tsdb = TsDBFactory.createDefault();

		//String stationName = "HEG01";
		//String sensorName = "Ta_200";


		String sensorName = "Ta_200";


		int count = 0;
		for(int i=10;i<25;i++) {
			String stationName = "HEG"+i;
			/*ArrayList<DataEntry> data = streamDB.readData(stationName, sensorName);
			for(DataEntry entry:data) {
				count++;
			}*/

			Iterator<Event> it = tsdb.streamStorage.queryRawEvents(stationName, null, null);
			String[] schema = tsdb.getStation(stationName).getSchema();
			int sensorIndex = -1;
			for(int sID=0;sID<schema.length;sID++) {
				if(schema[sID].equals(sensorName)) {
					sensorIndex = sID;
					break;
				}
			}
			while(it.hasNext()) {
				Event event = it.next();
				if(!Float.isNaN((float) event.getPayload()[sensorIndex])) {
					count++;
				}
			}
		}
		
		long time_start_intern = System.currentTimeMillis();
		for(int i=10;i<25;i++) {
			String stationName = "HEG"+i;
			/*ArrayList<DataEntry> data = streamDB.readData(stationName, sensorName);
			for(DataEntry entry:data) {
				count++;
			}*/

			Iterator<Event> it = tsdb.streamStorage.queryRawEvents(stationName, null, null);
			String[] schema = tsdb.getStation(stationName).getSchema();
			int sensorIndex = -1;
			for(int sID=0;sID<schema.length;sID++) {
				if(schema[sID].equals(sensorName)) {
					sensorIndex = sID;
					break;
				}
			}
			while(it.hasNext()) {
				Event event = it.next();
				if(!Float.isNaN((float) event.getPayload()[sensorIndex])) {
					count++;
				}
			}
		}
		long time_end_intern = System.currentTimeMillis();



		tsdb.close();
		long time_end = System.currentTimeMillis();
		System.out.println("count "+count);
		System.out.println(((time_end-time_start)/1000)+" s");
		System.out.println(((time_end_intern-time_start_intern))+" ms (intern)");
	}

}
