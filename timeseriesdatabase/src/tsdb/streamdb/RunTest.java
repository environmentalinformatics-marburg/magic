package tsdb.streamdb;
import java.util.ArrayList;


public class RunTest {
	
	public static void main(String[] args) {
		long time_start = System.currentTimeMillis();
		StreamDB streamDB = new StreamDB();
		
		
		
		/*
		final int station_count = 3*2*50;
		long total_count = 0;
		for(int sID=0;sID<station_count;sID++) {
			final int sensor_count = 20;
			long entry_count = 0;
			String stationName = "HEG"+sID;
			for(int s=0;s<sensor_count;s++) {				
				String sensorName = "Ta_"+s;				
				ArrayList<DataEntry> chunk = streamDB.readData(stationName, sensorName);
				entry_count += chunk.size();
			}
			System.out.println(stationName+"   "+entry_count);
			total_count += entry_count;
		}
		System.out.println("total_count: "+total_count);
		*/
		
		long total_value_count = 0;
		long total_sensor_count = 0;
		for(String stationName:streamDB.getStationNames()) {
			long station_value_count = 0;
			for(String sensorName:streamDB.getSensorNames(stationName)) {
				if(!sensorName.equals("Ta_200")) {
					continue;
				}
				ArrayList<DataEntry> data = streamDB.readData(stationName, sensorName);
				station_value_count += data.size();
				total_sensor_count++;
			}
			total_value_count += station_value_count;
			System.out.println(stationName+" station_value_count "+station_value_count);
		}
		System.out.println("total_sensor_count "+total_sensor_count);
		System.out.println("total_value_count "+total_value_count);
		
		
		
		
		streamDB.close();
		long time_end = System.currentTimeMillis();
		System.out.println(((time_end-time_start)/1000)+" s");
	}

}
