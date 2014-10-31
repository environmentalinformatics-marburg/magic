package tsdb.streamdb;
import java.util.ArrayList;


public class RunTest2 {

	public static void main(String[] args) {
		long time_start = System.currentTimeMillis();
		StreamDB streamDB = new StreamDB();
		
		//String stationName = "HEG01";
		//String sensorName = "Ta_200";
		
		String stationName = "HEG48";
		String sensorName = "Albedo";
		
		ArrayList<DataEntry> data = streamDB.readData(stationName, sensorName);
		
		for(DataEntry entry:data) {
			System.out.println(entry.timestamp+" "+entry.value);
		}
		
		
		streamDB.close();
		long time_end = System.currentTimeMillis();
		System.out.println(((time_end-time_start)/1000)+" s");
	}

}
