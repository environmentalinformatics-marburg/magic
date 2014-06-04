package structure;

import java.nio.file.Path;
import java.nio.file.Paths;




import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import dat_decode.DataUtil;
import dat_decode.TimeConverter;

public class UseCaseLoadDirectory1 {
	
	private static final Logger log = LogManager.getLogger("general");
	
	public static void main(String[] args){
		
		//Path rootPath = Paths.get("K:/incoming_ftp/adl-m/HEG");
		Path rootPath = Paths.get("K:/HEG_short");
		
		Database database = new Database();
		
		System.gc();
		Runtime runtime = Runtime.getRuntime();
		
		System.out.println("total memory: "+runtime.totalMemory()+" Bytes");
		
		System.out.println("read "+rootPath+" ...");
		database.loadDirectoryOfOneExploratory(rootPath);
		System.out.println("... end");
		
		System.gc();
		System.out.println("total memory: "+runtime.totalMemory()+" Bytes");
		
		database.printInfo();
		
		Storage storage = database.getStorage();
		
		//String sensorID = "HG03.Ts_10_MIN";
		String sensorID = "HG02.LT_200";
		//String sensorID = "HG01.LT_200";
		
		long startTimestamp = storage.queryFirstEntryOleMinutes(sensorID);
		long endTimestamp = storage.queryLastEntryOleMinutes(sensorID);
		
		System.out.println(sensorID+"\t"+TimeConverter.oleTimeMinutesToLocalDateTime(startTimestamp)+" - "+TimeConverter.oleTimeMinutesToLocalDateTime(endTimestamp));
		
		
		long queryTimeStart = startTimestamp+100;
		long queryTimeEnd = startTimestamp+1000;		
		
		float[] result = storage.queryTimeSeries(sensorID, queryTimeStart, queryTimeEnd);
		
		System.out.println();
		
		
		
		System.out.print("query: "+sensorID+"\t");
		System.out.println(TimeConverter.oleTimeMinutesToLocalDateTime(queryTimeStart)+" - "+TimeConverter.oleTimeMinutesToLocalDateTime(queryTimeEnd));
		System.out.println();
		
		DataUtil.printArray(result, 100);
		
		float[] result2 = storage.queryAggregatedTimeSeries(sensorID, queryTimeStart, queryTimeEnd,30);
		
		System.out.println();
		DataUtil.printArray(result2, 100);
		
	}

}
