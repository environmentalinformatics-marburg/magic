package structure;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import dat_decode.TimeConverter;

public class Storage {
	
	static class DataStorage {
		public long firstEntryTimeOleMinutes;
		public Float[] data;
		public DataStorage(long firstEntryTimeOleMinutes, Float[] data) {
			this.firstEntryTimeOleMinutes = firstEntryTimeOleMinutes;
			this.data = data;
		}
	}
	
	private double storageTimeStep;
	
	private Map<String,DataStorage>   storageMap;
	
	public Storage() {
		storageMap = new HashMap<String, Storage.DataStorage>();
	}
	
	public void writeTimeSeries(String serialNumber, float[] timeSeries, long firstEntryTimeOleMinutes, long timeStepMinutes) {
		System.out.println("write to database: "+serialNumber+"\t"+firstEntryTimeOleMinutes+"\t"+timeSeries.length+"\t"+timeStepMinutes+"\t"+TimeConverter.oleTimeMinutesToLocalDateTime(firstEntryTimeOleMinutes)+" to "+TimeConverter.oleTimeMinutesToLocalDateTime(firstEntryTimeOleMinutes+(timeSeries.length*timeStepMinutes)));
		
		DataStorage dataStorage = storageMap.get(serialNumber);
		if(dataStorage==null) {
			Float[] data = new Float[timeSeries.length];
			for(int i=0;i<data.length;i++) {
				data[i] = timeSeries[i];
			}
			dataStorage = new DataStorage(firstEntryTimeOleMinutes, data);
			storageMap.put(serialNumber, dataStorage);
		} else {
			long minTime = dataStorage.firstEntryTimeOleMinutes<firstEntryTimeOleMinutes?dataStorage.firstEntryTimeOleMinutes:firstEntryTimeOleMinutes;
			long maxTime = dataStorage.firstEntryTimeOleMinutes+dataStorage.data.length>firstEntryTimeOleMinutes+timeSeries.length?dataStorage.firstEntryTimeOleMinutes+dataStorage.data.length:firstEntryTimeOleMinutes+timeSeries.length;
			Float[] data = new Float[(int) (maxTime-minTime)];
			for(int i=0;i<dataStorage.data.length;i++) {
				data[(int) (dataStorage.firstEntryTimeOleMinutes-minTime+i)] = dataStorage.data[i];
			}
			for(int i=0;i<timeSeries.length;i++) {
				data[(int) (firstEntryTimeOleMinutes-minTime+i)] = timeSeries[i];
			}
		}
		
	}
	
		
	public float[] readTimeSeries(String serialNumber, long firstEntryTimeOleMinutes, long lastEntryTimeOleMinutes) {
		return null;
	}
	
	public void printInfo() {
		System.out.println(storageMap.size()+"\ttimeseries");
	}

}
