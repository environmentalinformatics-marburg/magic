package structure;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import dat_decode.TimeConverter;

public class Storage {
	
	static class DataStorage {
		public long firstEntryOleMinutes; // unit ST (storage time)
		public Float[] data;
		public DataStorage(long firstEntryOleMinutes, Float[] data) {
			this.firstEntryOleMinutes = firstEntryOleMinutes;
			this.data = data;
		}
	}
	
	private static final Logger log = LogManager.getLogger("general");
	
	private final long storageTimeStepMinutes;
	
	private Map<String,DataStorage>   storageMap;
	
	public Storage(long storageTimeStepMinutes) {
		storageMap = new HashMap<String, Storage.DataStorage>();
		this.storageTimeStepMinutes = storageTimeStepMinutes;
	}
	
	public float[] convertTimeSeries(float[] timeSeries, long timeStepMinutes) {
		if(timeStepMinutes==storageTimeStepMinutes) {// no conversion
			return timeSeries;
		}
		if(timeStepMinutes<storageTimeStepMinutes) {
			//System.out.println("not implemented");
			return null;
		}
		int length = (int) ((((timeSeries.length-1)*timeStepMinutes)/storageTimeStepMinutes)+1);
		if(timeStepMinutes>1000) {
			//System.out.println(timeSeries.length+" with "+timeStepMinutes+" -> "+length);
			return null;
		}		
		float[] result = new float[length];
		for(int i=0;i<result.length;i++) {
			result[i] = Float.NaN;
		}
		for(int i=0;i<timeSeries.length;i++) {
			result[(int) ((i*timeStepMinutes)/storageTimeStepMinutes)] = timeSeries[i];
		}
		return result;
	}
	
	public void insertTimeSeries(String serialNumber, float[] timeSeries, long firstEntryTimeOleMinutes, long timeStepMinutes) {
		float[] data = convertTimeSeries(timeSeries,timeStepMinutes);
		if(data==null) {
			System.out.println("not inserted:\t"+serialNumber);
			return;
		}
		insertTimeSeries(serialNumber,data,firstEntryTimeOleMinutes);
	}
	
	public void insertTimeSeries(String serialNumber, float[] timeSeries, long firstEntryTimeOleMinutes) {
		
		
		LocalDateTime firstDateTime = TimeConverter.oleTimeMinutesToLocalDateTime(firstEntryTimeOleMinutes);
		LocalDateTime lastDateTime = TimeConverter.oleTimeMinutesToLocalDateTime(firstEntryTimeOleMinutes+(timeSeries.length*storageTimeStepMinutes));
		
		System.out.println("insert into database: "+serialNumber+"\t\t"+firstDateTime+" - "+lastDateTime+"\t entries: "+timeSeries.length);
		
		
		DataStorage dataStorage = storageMap.get(serialNumber);
		if(dataStorage==null) {
			Float[] data = new Float[timeSeries.length];
			for(int i=0;i<data.length;i++) {
				data[i] = timeSeries[i];
			}
			dataStorage = new DataStorage(firstEntryTimeOleMinutes, data);
			storageMap.put(serialNumber, dataStorage);
		} else {			
			if(firstEntryTimeOleMinutes<dataStorage.firstEntryOleMinutes) {
				log.warn("wrong data order");
				return;
			}
			
			int offset = (int) (firstEntryTimeOleMinutes-dataStorage.firstEntryOleMinutes);
			
			Float[] data = new Float[offset+timeSeries.length];
			
			for(int i=0;i<dataStorage.data.length;i++) {
				data[i] = dataStorage.data[i];
			}
			
			//TODO
			
			
			
			
			
			/*
			long minTime = dataStorage.firstEntryOleMinutes<firstEntryTimeOleMinutes?dataStorage.firstEntryOleMinutes:firstEntryTimeOleMinutes;
			long maxTime = dataStorage.firstEntryOleMinutes+dataStorage.data.length>firstEntryTimeOleMinutes+timeSeries.length?dataStorage.firstEntryOleMinutes+dataStorage.data.length:firstEntryTimeOleMinutes+timeSeries.length;
			long startIndex = dataStorage.firstEntryOleMinutes/storageTimeStepMinutes;
			long minIndex = minTime/storageTimeStepMinutes;
			long maxIndex = maxTime/storageTimeStepMinutes;
			//Float[] data = new Float[(int) (maxIndex-minIndex)+1];
			Float[] data = new Float[(int) (maxTime-minTime)+1];
			log.trace(serialNumber+"\tminTime\t"+TimeConverter.oleTimeMinutesToLocalDateTime(minTime)+"\t-\t"+"maxTime\t"+TimeConverter.oleTimeMinutesToLocalDateTime(maxTime)+": "+data.length);
			
			for(int i=0;i<dataStorage.data.length;i++) {
				data[(int) (dataStorage.firstEntryOleMinutes-minTime+i)] = dataStorage.data[i];
			}
			for(int i=0;i<timeSeries.length;i++) {
				data[(int) (firstEntryTimeOleMinutes-minTime+i)] = timeSeries[i];
			}
			
			dataStorage.firstEntryOleMinutes = minTime;
			dataStorage.data = data;*/
		}
		
	}
	
	public long queryFirstEntryOleMinutes(String serialNumber) {
		DataStorage dataStorage = storageMap.get(serialNumber);
		if(dataStorage==null) {
			throw new RuntimeException("serialNumber not found: "+serialNumber);
		}
		return dataStorage.firstEntryOleMinutes;
	}
	
	public long queryLastEntryOleMinutes(String serialNumber) {
		DataStorage dataStorage = storageMap.get(serialNumber);
		if(dataStorage==null) {
			throw new RuntimeException("serialNumber not found: "+serialNumber);
		}
		return dataStorage.firstEntryOleMinutes+(dataStorage.data.length*storageTimeStepMinutes);
	}
	
		
	public float[] queryTimeSeries(String serialNumber, long firstEntryQueryOleMinutes, long lastEntryQueryOleMinutes) {
		
		DataStorage dataStorage = storageMap.get(serialNumber);
		
		if(dataStorage==null) {
			throw new RuntimeException("serialNumber not found: "+serialNumber);
		}
				
		float[] result = new float[(int) (lastEntryQueryOleMinutes-firstEntryQueryOleMinutes +1)];
		
		for(int i=0;i<result.length;i++) {
			result[i] = Float.NaN;
		}
		
		if(dataStorage.firstEntryOleMinutes<=firstEntryQueryOleMinutes) { // dataStorage.firstEntryTimeOleMinutes<=firstEntryTimeOleMinutes         ......DDDDDDDQQQQQQQDDDDDDD.........
			int firstIndex = (int) (firstEntryQueryOleMinutes - dataStorage.firstEntryOleMinutes);
			int lastIndex  = (int)  (lastEntryQueryOleMinutes - dataStorage.firstEntryOleMinutes);
			if(firstIndex>=dataStorage.data.length) { // no data
				return result;
			}
			if(lastIndex>=dataStorage.data.length) {
				lastIndex = dataStorage.data.length-1;
			}
			int resultIndex=0;
			for(int i=firstIndex;i<=lastIndex;i++) {
				result[resultIndex] = dataStorage.data[i];
				resultIndex++;
			}
			return result;
		} else {  // firstEntryTimeOleMinutes < dataStorage.firstEntryTimeOleMinutes     ........QQQQQQDDDDDDDDDDDDDD.......
			throw new RuntimeException("firstEntryQueryOleMinutes < dataStorage.firstEntryTimeOleMinutes not implemented");
			/*int firstResultIndex = (int) (dataStorage.firstEntryTimeOleMinutes-firstEntryQueryOleMinutes);
			int lastResultIndex = (int) (dataStorage.firstEntryTimeOleMinutes+dataStorage.data.length-firstEntryQueryOleMinutes);
			
			if(firstResultIndex>=result.length) { // no data
				return result;
			}
			if(lastResultIndex>=)
			
			int dataIndex = 0;
			for(int i=firstResultIndex;i<=lastResultIndex;i++) {
				result[i] = dataStorage.data[dataIndex];
				dataIndex++;
			}*/
		}
	}
	
	public float[] queryAggregatedTimeSeries(String serialNumber, long firstEntryQueryOleMinutes, long lastEntryQueryOleMinutes, int timeStepMinutes) {
		
		float[] data = queryTimeSeries(serialNumber,firstEntryQueryOleMinutes,lastEntryQueryOleMinutes);
		
		long diff = lastEntryQueryOleMinutes-firstEntryQueryOleMinutes;
		
		float[] result = new float[(int) (((data.length-1)*storageTimeStepMinutes)/timeStepMinutes)+1];
		
		for(int i=0;i<result.length;i++) {
			result[i] = Float.NaN;
		}
		
		for(int i=0;i<data.length;i++) { // calc real aggregation
			int pos = (int) ((i*storageTimeStepMinutes)/timeStepMinutes);
			if(!Float.isNaN(data[i])) {
				result[pos] = data[i];
			}
		}		
		
		return result;
	}
	
	public void printInfo() {
		System.out.println("storage info: "+storageMap.size()+"\ttimeseries");
		/*
		int c=0;
		for(String key:storageMap.keySet()) {
			System.out.print(key+"\t");
			c++;
			if(c%10==0) {
				System.out.println();
			}
		}
		System.out.println();*/
		
	}

}
