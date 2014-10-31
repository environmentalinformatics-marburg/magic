package tsdb.streamdb;
import java.util.ArrayList;


public class RunTest3 {

	public static void main(String[] args) {
		long time_start = System.currentTimeMillis();
		StreamDB streamDB = new StreamDB();

		//String stationName = "HEG01";
		//String sensorName = "Ta_200";


		String sensorName = "Ta_200";
		
			
		int count = 0;
		for(int i=10;i<25;i++) {
			String stationName = "HEG"+i;
			ArrayList<DataEntry> data = streamDB.readData(stationName, sensorName);
			for(DataEntry entry:data) {
				count++;
			}
		}
		
		long time_start_intern = System.currentTimeMillis();
		for(int i=10;i<25;i++) {
			String stationName = "HEG"+i;
			ArrayList<DataEntry> data = streamDB.readData(stationName, sensorName);
			for(DataEntry entry:data) {
				count++;
			}
		}
		long time_end_intern = System.currentTimeMillis();
		
		System.out.println("count "+count);


		streamDB.close();
		long time_end = System.currentTimeMillis();
		System.out.println(((time_end-time_start)/1000)+" s");
		System.out.println(((time_end_intern-time_start_intern))+" ms (intern)");
	}

}
