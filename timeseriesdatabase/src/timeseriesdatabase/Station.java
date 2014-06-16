package timeseriesdatabase;

import java.io.IOException;
import java.lang.reflect.Field;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Array;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.TreeMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

/**
 * This class contains metadata that is associated with a station (plotID).
 * @author Stephan Wöllauer
 *
 */
public class Station {
	
	private static final Logger log = Util.log;
	
	public TimeSeriesDatabase timeSeriesDatabase;
	
	public String plotID;
	
	public Map<String, String> propertyMap;
	
	public Map<String,String> sensorNameTranlationMap;

	private String generalStationName;
	
	public Set<Long> insertedTimestampSet = null; // *** duplicate workaround
	
	public Station(TimeSeriesDatabase timeSeriesDatabase, String generalStationName, String plotID, Map<String, String> propertyMap) {
		this.generalStationName = generalStationName;
		this.timeSeriesDatabase = timeSeriesDatabase;
		this.plotID = plotID;
		this.propertyMap = propertyMap;
		
		sensorNameTranlationMap = new HashMap<String, String>();
		
		//System.out.println(propertyMap);
		
		if(!plotID.equals(propertyMap.get("PLOTID"))) {
			log.error("wrong plotID");
		}
		
	}
	
	public LoggerType getLoggerType() {
		LoggerType loggerType = timeSeriesDatabase.loggerTypeMap.get(propertyMap.get("LOGGER")); 
		if(loggerType==null) {
			log.warn("logger type not found: ");
			System.out.println("logger type not found: ");
		}
		return loggerType;
	}

	public void loadDirectoryOfOneStation(Path stationPath) {
		insertedTimestampSet = new HashSet<Long>(); // *** duplicate workaround
		log.info("load station:\t"+stationPath+"\tplotID:\t"+plotID);
		System.out.println("load station:\t"+stationPath+"\tplotID:\t"+plotID);
		
		Map<String,List<Path>> fileNameMap = new TreeMap<String,List<Path>>(); // prefix needs to be ordered!
		
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(stationPath, x -> x.toString().endsWith(".dat"));
			for(Path path:stream) {				
				String fileName = path.getFileName().toString();
				String prefix = fileName.substring(0,fileName.indexOf('_'));
				
				List<Path> list = fileNameMap.get(prefix);
				if(list==null) {
					list = new ArrayList<Path>();
					fileNameMap.put(prefix, list);
				}
				list.add(path);
			}			
		} catch (IOException e) {
			e.printStackTrace();
		}
		

		
		for(Entry<String, List<Path>> entry:fileNameMap.entrySet()) {
			String prefix = entry.getKey();
			List<Path> pathList = entry.getValue();	
			
			//List<UDBFTimeSeries> timeSeriesList = new ArrayList<UDBFTimeSeries>();
			List<List<Event>> eventsList = new ArrayList<List<Event>>();
			
			for(Path path:pathList) {
				try {
					UDBFTimeSeries timeSeries = readUDBFTimeSeries(path);
					List<Event> eventList = translateToEvents(timeSeries);
					eventsList.add(eventList);
					//timeSeriesList.add(timeSeries);
					} catch (Exception e) {
						log.error("file not read: "+path+"\t"+e);
					}
			}
			
			
			for(List<Event> eventList:eventsList) {
				//loadIntoDatabaseUDBFFile(timeSeries);
				//System.out.println(timeSeries.filename);

				if(eventList!=null) {				
					for(Event event:eventList) {						
						
						Object[] payload = event.getPayload();
						long timestamp = event.getTimestamp();						
						
						if(insertedTimestampSet!=null) {
							if(!insertedTimestampSet.contains(timestamp)) {
								//System.out.println(payload[1]);
								timeSeriesDatabase.store.pushEvent(plotID, payload, timestamp);
								insertedTimestampSet.add(timestamp);
							}
						} else {			
							timeSeriesDatabase.store.pushEvent(plotID, event.getPayload(),event.getTimestamp());
						}
						
						
						
					}
				}

			}			
			
		}		
		
		insertedTimestampSet = null; // *** duplicate workaround
		
		timeSeriesDatabase.store.flushStream(plotID);
	}
	
	private String translateInputSensorName(String sensorName) {
		String resultName = sensorNameTranlationMap.get(sensorName);
		if(resultName!=null) {
			return resultName;
		}
		resultName = timeSeriesDatabase.generalStationMap.get(generalStationName).sensorNameTranlationMap.get(sensorName);
		if(resultName!=null) {
			return resultName;
		}
		LoggerType loggerType = getLoggerType();
		resultName = loggerType.sensorNameTranlationMap.get(sensorName);
		if(resultName!=null) {
			return resultName;
		}
		String[] schemaSensorNames = loggerType.sensorNames;
		for(String schemaSensorName:schemaSensorNames) {
			if(schemaSensorName.equals(sensorName)) {
				return sensorName;
			}
		}
		return null;
	}
	
	
	public UDBFTimeSeries readUDBFTimeSeries(Path filename) throws IOException {
		log.trace("load UDBF file:\t"+filename+"\tplotID:\t"+plotID);
		UniversalDataBinFile udbFile = new UniversalDataBinFile(filename);
		UDBFTimeSeries udbfTimeSeries = udbFile.getUDBFTimeSeries();
		udbFile.close();
		return udbfTimeSeries;
	}
	
	
	
	public List<Event> translateToEvents(UDBFTimeSeries udbfTimeSeries) {
		List<Event> eventList = new ArrayList<Event>();
		
		
		
SensorHeader[] sensorHeaders = udbfTimeSeries.sensorHeaders;
		
		int[] eventPos = new int[sensorHeaders.length];
		
		LoggerType loggerType = getLoggerType();
		
		String[] sensorNames = getLoggerType().sensorNames;
		
		/*ArrayList<String> list = new ArrayList<String>();
		for(Attribute attribute:schema) {
			list.add(attribute.getAttributeName());
		}*/
		//System.out.println(getLoggerType().typeName+" schema: "+list);
		
		for(int sensorIndex=0; sensorIndex<sensorHeaders.length; sensorIndex++) {
			eventPos[sensorIndex] = -1;
			SensorHeader sensorHeader = sensorHeaders[sensorIndex];
			String rawSensorName = sensorHeader.name;
			if(!timeSeriesDatabase.ignoreSensorNameSet.contains(rawSensorName)) {
				String sensorName = translateInputSensorName(rawSensorName);
				//System.out.println(sensorHeader.name+"->"+sensorName);
				if(sensorName != null) {
					for(int schemaIndex=0;schemaIndex<sensorNames.length;schemaIndex++) {
						String schemaSensorName = sensorNames[schemaIndex];
						if(schemaSensorName.equals(sensorName)) {
							eventPos[sensorIndex] = schemaIndex;
						}
					}
				}
				if(eventPos[sensorIndex] == -1) {
					if(sensorName==null) {
						log.warn("sensor name not in translation map: "+rawSensorName+" -> "+sensorName+"\t"+plotID+"\t"+udbfTimeSeries.filename+"\t"+propertyMap.get("LOGGER"));
					} else {
						log.trace("sensor name not in schema: "+rawSensorName+" -> "+sensorName+"\t"+plotID+"\t"+udbfTimeSeries.filename+"\t"+propertyMap.get("LOGGER"));
					}
				}
			}
		}
		
		try {
		
		int[] sensorPos = new int[sensorNames.length];
		for(int i=0;i<sensorPos.length;i++) {
			sensorPos[i] = -1;
		}
		int validSensorCount = 0;
		for(int i=0;i<eventPos.length;i++) {
			if(eventPos[i]>-1) {
				validSensorCount++;
				sensorPos[eventPos[i]] = i;
			}
		}
		
		if(validSensorCount<1) {
			log.trace("no fitting sensors in "+udbfTimeSeries.filename);
			return null;
		}
		
		
		float[] min = new float[sensorNames.length];
		float[] max = new float[sensorNames.length];
		
		for(int i=0;i<sensorNames.length;i++) {
			Sensor sensor = timeSeriesDatabase.sensorMap.get(sensorNames[i]);
			if(sensor!=null) {
				min[i] = sensor.min;
				max[i] = sensor.max;
			} else {
				min[i] = -Float.MAX_VALUE;
				max[i] = Float.MAX_VALUE;
			}
		}

		Object[] payload = new Object[loggerType._schema.length];
		short sampleRate = (short) udbfTimeSeries.timeConverter.getTimeStep().toMinutes();
		payload[loggerType._schema.length-1] = sampleRate; 
		for(int rowIndex=0;rowIndex<udbfTimeSeries.time.length;rowIndex++) {
			float[] row = udbfTimeSeries.data[rowIndex];
			for(int attrNr=0;attrNr<sensorNames.length;attrNr++) {
				if(sensorPos[attrNr]<0) {
					payload[attrNr] = Float.NaN;
				} else {					
					float value = row[sensorPos[attrNr]];
					
					if(value<min[attrNr]||max[attrNr]<value) {
						value = Float.NaN;
					} 
					
					payload[attrNr] = value;
				}
				//System.out.print(payload[attrNr]+"\t");
			}
			//System.out.println("push: "+udbfTimeSeries.time[rowIndex]);
			if(udbfTimeSeries.time[rowIndex]==58508670) {
				System.out.println("write time 58508670 in "+plotID+"\t"+udbfTimeSeries.filename);
			}
			long timestamp = udbfTimeSeries.time[rowIndex];
			/*try {
				Iterator<Event> it = timeSeriesDatabase.store.getHistoryPoint(plotID, timestamp);
				if(it!=null) {
					timeSeriesDatabase.store.pushEvent(plotID, payload, timestamp);
				}
			} catch(Exception e) {
				timeSeriesDatabase.store.pushEvent(plotID, payload, timestamp);
			}
			//timeSeriesDatabase.store.pushEvent(plotID, payloadTest, udbfTimeSeries.time[rowIndex]);
			//System.out.println();*/
			
			
			eventList.add(new Event(Arrays.copyOf(payload, payload.length), timestamp));
			
			/*
			if(insertedTimestampSet!=null) {
				if(!insertedTimestampSet.contains(timestamp)) {
					timeSeriesDatabase.store.pushEvent(plotID, payload, timestamp);
					insertedTimestampSet.add(timestamp);
				}
			} else {			
				timeSeriesDatabase.store.pushEvent(plotID, payload, timestamp);
			}
			*/
			
			
			
		}
		
		} catch (Exception e) {
			e.printStackTrace();
		}		
		
		
		
		
		return eventList;
	}
	
	
	

}
