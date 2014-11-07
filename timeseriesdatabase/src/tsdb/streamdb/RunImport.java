package tsdb.streamdb;
import java.util.ArrayList;
import java.util.Iterator;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.Marker;
import org.apache.logging.log4j.MarkerManager;

import de.umr.jepc.store.Event;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.TsDBFactory;

public class RunImport {
	
	private static final Logger log = LogManager.getLogger();
	public static final Marker tsdbImportMarker = MarkerManager.getMarker("tsdbImport");

	public static void main(String[] args) {
		
		long time_start = System.currentTimeMillis();

		StreamDB streamDB = new StreamDB(TsDBFactory.STREAMDB_PATH_PREFIX);

		//insertTestData(streamDB);
		insertTsDB(streamDB);

		streamDB.close();
		
		long time_end = System.currentTimeMillis();
		System.out.println(((time_end-time_start)/1000)+" s");
	}

	private static void insertTsDB(StreamDB streamDB) {
		TsDB tsdb = TsDBFactory.createDefault();
		ArrayList<String> stationNames = new ArrayList<String>();
		for(Station station:tsdb.getStations()) {
			stationNames.add(station.stationID);			
		}
		int counter = 0;
		for(String stationName:stationNames) {
			
			if(counter%25==0) {
				tsdb.close();
				tsdb = TsDBFactory.createDefault();
				System.gc();
			}
			
			Station station = tsdb.getStation(stationName);
			Iterator<Event> it = tsdb.streamStorage.queryRawEvents(station.stationID, null, null);

			if(it!=null&&it.hasNext()) {
				String[] schema = station.getSchema();
				final int n = schema.length;
				ArrayList<DataEntry>[] sensor = new ArrayList[n];
				for(int i=0;i<n;i++) {
					sensor[i] = new ArrayList<DataEntry>(1000);
				}				
				while(it.hasNext()) {
					Event event = it.next();
					int t = (int) event.getTimestamp();
					Object[] data = event.getPayload();
					for(int i=0;i<n;i++) {
						float value = (float) data[i];
						if(!Float.isNaN(value)) {
							sensor[i].add(new DataEntry(t, value));
						}
					}
				}
				StringBuilder s = new StringBuilder();
				s.append(station.stationID);
				for(int i=0;i<n;i++) {
					if(!sensor[i].isEmpty()) {
						s.append(' ');
						s.append(schema[i]);
						s.append(':');
						s.append(sensor[i].size());
						streamDB.insertData(station.stationID, schema[i], sensor[i].toArray(new DataEntry[0]));
					}
				}
				log.info(tsdbImportMarker,s);
			}
			counter++;
		}

		tsdb.close();
	}

}
