package timeseriesdatabase;

import java.lang.reflect.InvocationTargetException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


public class Sensor {
	
	private static final Logger log = LogManager.getLogger("general");
	
	public final String sensorID;
	public Storage storage;
	
	public Sensor(String sensorID, Storage storage) {
		this.sensorID = sensorID;
		this.storage = storage;
	}
	
	/*public void loadTimeSeries(long firstTimeStamp, long lastTimeStamp, float[] data) {
		/*if(!streamNames.contains(sensorID)) {
			log.trace("register stream:\t"+sensorID);
			eventStore.registerStream(sensorID, FLOAT_ONE_SCHEMA);
			streamNames.add(sensorID);
		}*/
		
		
		//log.trace("write to storage:\t"+sensorID/*+"\t\t time stamp: "+firstTimeStamp+"\ttime step: "+lastTimeStamp+"\tcount: "+data.length*/);
		//storage.writeTimeSeries(sensorID, firstTimeStamp, data);
		
		
		
	//}*/

	public void loadTimeSeries(long[] time, float[] data) {
		//log.trace("write to storage:\t"+sensorID/*+"\t\t time stamp: "+firstTimeStamp+"\ttime step: "+lastTimeStamp+"\tcount: "+data.length*/);
		
		storage.writeTimeSeries(sensorID, time, data);
		
	}

}
