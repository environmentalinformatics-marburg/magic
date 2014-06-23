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

import util.Util;
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
	
	/**
	 * Stream name of this station
	 */
	public String plotID;
	
	public double geoPoslongitude;
	public double geoPosLatitude;
	
	/**
	 * general properties like logger type
	 */
	public Map<String, String> propertyMap;
	
	/**
	 * translation map: input sensor name -> database sensor name
	 * This map contains only entries that are specific for this Station (or plotID)
	 */
	public Map<String,String> sensorNameTranlationMap;

	/**
	 * The general name of this plotID for example HEG03 it is HEG
	 * This name belongs to a GeneralStation Object
	 */
	public String generalStationName;
	
	/**
	 * list of stations of same general station id ordered by position difference to this station
	 */
	public List<Station> nearestStationList;
	
	/**
	 * This set contains all time stamps of inserted events.
	 */
	public Set<Long> insertedTimestampSet = null;
	
	/**
	 * workaround for not ordered timestamps
	 */
	public Map<Long,Event> eventMap = null;
	
	/**
	 * The greatest time stamp that was inserted so far.
	 */
	public long lastInsertTimestamp;
	
	public Station(TimeSeriesDatabase timeSeriesDatabase, String generalStationName, String plotID, Map<String, String> propertyMap) {
		this.lastInsertTimestamp = -1;
		this.generalStationName = generalStationName;
		this.timeSeriesDatabase = timeSeriesDatabase;
		this.plotID = plotID;
		this.propertyMap = propertyMap;
		this.geoPoslongitude = Float.NaN;
		this.geoPosLatitude = Float.NaN;
		
		sensorNameTranlationMap = new HashMap<String, String>();

		
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

	/**
	 * Reads all UDBF-Files of one directory and inserts the data entries into database
	 * @param stationPath
	 */
	public void loadDirectoryOfOneStation(Path stationPath) {
		insertedTimestampSet = new HashSet<Long>(); // *** duplicate workaround
		eventMap = new TreeMap<Long,Event>(); // *** workaround for not ordered timestamps
		log.info("load station:\t"+stationPath+"\tplotID:\t"+plotID);
		System.out.println("load station:\t"+stationPath+"\tplotID:\t"+plotID);
		
		Map<String,List<Path>> fileNameMap = new TreeMap<String,List<Path>>(); // TreeMap because prefix needs to be ordered!
		
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
			
			List<List<Event>> eventsList = new ArrayList<List<Event>>();
			
			for(Path path:pathList) {
				try {
					UDBFTimeSeries timeSeries = readUDBFTimeSeries(path);
					List<Event> eventList = translateToEvents(timeSeries);
					if(eventList!=null) {
						eventsList.add(eventList);
					}
					} catch (Exception e) {
						log.error("file not read: "+path+"\t"+e);
					}
			}
			
			@SuppressWarnings("unchecked")
			Iterator<Event>[] iterators = new Iterator[eventsList.size()];
			
			for(int i=0;i<eventsList.size();i++) {
				iterators[i]=eventsList.get(i).iterator();
			}
			
			Event[] currentEvent = new Event[iterators.length];
			
			for(int i=0;i<iterators.length;i++) {
				if(iterators[i].hasNext()) {
					currentEvent[i] = iterators[i].next();
				}				
			}
			
			long currentTimestamp = -1;
			Event collectorEvent = null;
			
			while(true) {
				
				int minIndex=-1;
				long minTimeStamp = Long.MAX_VALUE;
				for(int i=0;i<iterators.length;i++) {
					if(currentEvent[i]!=null) {
						if(currentEvent[i].getTimestamp()<minTimeStamp) {
							minTimeStamp = currentEvent[i].getTimestamp();
							minIndex = i;
						}
					}
				}
				
				if(minIndex<0) {
					break;
				}
				
				if(currentTimestamp<currentEvent[minIndex].getTimestamp()) {
					if(collectorEvent!=null) {
						pushCheckedEvent(collectorEvent);
					}
					currentTimestamp = currentEvent[minIndex].getTimestamp();
					collectorEvent = null;
				}
				if(collectorEvent==null) {
					collectorEvent = currentEvent[minIndex];
				} else {
					Object[] payload = currentEvent[minIndex].getPayload();
					Object[] collectorPayload = collectorEvent.getPayload();
					for(int i=0;i<collectorPayload.length-1;i++) { // TODO
						if(!Float.isNaN((float) payload[i])&&Float.isNaN((float) collectorPayload[i])) {
							collectorPayload[i] = payload[i];
						}
					}
				}
				
				if(iterators[minIndex].hasNext()) {
					currentEvent[minIndex] = iterators[minIndex].next();
				} else {
					currentEvent[minIndex] = null;
				}
				
			}
			
			if(collectorEvent!=null) {
				pushCheckedEvent(collectorEvent);
			}			
		}		
		
		insertedTimestampSet = null; // *** duplicate workaround
		
		// *** workaround for not ordered timestamps
		for(Event event:eventMap.values()) {
			//System.out.println(event.getTimestamp());
			pushEvent(event.getPayload(),event.getTimestamp());
		}	
		eventMap = null; 
		
		timeSeriesDatabase.store.flushStream(plotID);
	}
	
	/**
	 * pushs event into database if there has not been inserted a same time stamp before.
	 * @param event
	 */
	private void pushCheckedEvent(Event event) {
		Object[] payload = event.getPayload();
		long timestamp = event.getTimestamp();						
		
		if(insertedTimestampSet!=null) {
			if(!insertedTimestampSet.contains(timestamp)) {
				//pushEvent(payload,timestamp);
				// *** workaround for not ordered timestamps
				eventMap.put(event.getTimestamp(), event);
				insertedTimestampSet.add(timestamp);
			}
		} else {			
			//pushEvent(payload,timestamp);
			// *** workaround for not ordered timestamps
			eventMap.put(event.getTimestamp(), event);
		}
	}
	
	/**
	 * psuh event into data base and updates lastInsertTimestamp.
	 * @param payload
	 * @param timestamp
	 */
	private void pushEvent(Object[] payload, long timestamp) {
		timeSeriesDatabase.store.pushEvent(plotID, payload,timestamp);
		if(lastInsertTimestamp>timestamp) {
			log.warn("insert outdated timestemp: "+timestamp+" newest is "+lastInsertTimestamp+"\t"+plotID);
		} else {
			lastInsertTimestamp = timestamp;
		}
	}
	
	
	/**
	 * This method determines the database sensor name out of an input sensor name.
	 * Steps:
	 * 1. check if there an entry in the plotID specific sensorNameTranlationMap
	 * 2. else check if there is an entry in the general station  sensorNameTranlationMap
	 * 3. else check if there is an entry in the logger type sensorNameTranlationMap
	 * 4. else return null (either input sensor name and database sensor name are identical or sensor name is unknown / not used)
	 * @param sensorName
	 * @return
	 */
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
	
	
	/**
	 * Reads an UDBF-File and return structured data as UDBFTimeSeries Object.
	 * @param filename
	 * @return
	 * @throws IOException
	 */
	public UDBFTimeSeries readUDBFTimeSeries(Path filename) throws IOException {
		log.trace("load UDBF file:\t"+filename+"\tplotID:\t"+plotID);
		UniversalDataBinFile udbFile = new UniversalDataBinFile(filename);
		UDBFTimeSeries udbfTimeSeries = udbFile.getUDBFTimeSeries();
		udbFile.close();
		return udbfTimeSeries;
	}
	
	
	/**
	 * Convertes rows of input file data into events with matching schema of the event stream of this plotID 
	 * @param udbfTimeSeries
	 * @return List of Events, time stamp ordered 
	 */
	public List<Event> translateToEvents(UDBFTimeSeries udbfTimeSeries) {
		List<Event> resultList = new ArrayList<Event>(); // result list of events	
		
		//mapping: UDBFTimeSeries column index position -> Event column index position;    eventPos[i] == -1 -> no mapping		
		int[] eventPos = new int[udbfTimeSeries.sensorHeaders.length];  
		
		LoggerType loggerType = getLoggerType();
		
		//sensor names contained in event stream schema
		String[] sensorNames = getLoggerType().sensorNames;
		

		//creates mapping eventPos   (  udbf pos -> event pos )
		for(int sensorIndex=0; sensorIndex<udbfTimeSeries.sensorHeaders.length; sensorIndex++) {
			eventPos[sensorIndex] = -1;
			SensorHeader sensorHeader = udbfTimeSeries.sensorHeaders[sensorIndex];
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
		
		
		//mapping event index position -> sensor index position 
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
			return null; //all event columns are empty
		}
		
		//create events
		Object[] payload = new Object[loggerType.schema.length];
		short sampleRate = (short) udbfTimeSeries.timeConverter.getTimeStep().toMinutes();
		payload[loggerType.schema.length-1] = sampleRate; 
		//iterate over input rows
		for(int rowIndex=0;rowIndex<udbfTimeSeries.time.length;rowIndex++) {
			// one input row
			float[] row = udbfTimeSeries.data[rowIndex];
			
			//fill event columns with input data values
			for(int attrNr=0;attrNr<sensorNames.length;attrNr++) {
				if(sensorPos[attrNr]<0) { // no input column
					payload[attrNr] = Float.NaN;
				} else {
					float value = row[sensorPos[attrNr]];				
					payload[attrNr] = value;
				}
			}

			//just for testing purpose
			if(udbfTimeSeries.time[rowIndex]==58508670) {
				System.out.println("write time 58508670 in "+plotID+"\t"+udbfTimeSeries.filename);
			}
			long timestamp = udbfTimeSeries.time[rowIndex];
			resultList.add(new Event(Arrays.copyOf(payload, payload.length), timestamp));		
		}
		
		return resultList;
	}

	/**
	 * Get base aggregated data
	 * @param querySensorNames sensors in the result schema; if null all available sensors are in the result schema
	 * @param start start time stamp, if null start from oldest data
	 * @param end end time stamp, if null get data up to newest data
	 * @return
	 */
	public TimeSeries queryBaseAggregatedData(String[] querySensorNames, Long start, Long end) {
		String[] schemaSensorNames = getLoggerType().sensorNames;
		BaseAggregationProcessor baseAggregationProcessor = new BaseAggregationProcessor(timeSeriesDatabase,schemaSensorNames,querySensorNames);
		Iterator<Event> it;
		if(start!=null) {
			long startTime = BaseAggregationTimeUtil.calcMinRawTimestampOfBaseAggregationTimestamp(start);
			if(end!=null) {
				long endTime = BaseAggregationTimeUtil.calcMaxRawTimestampOfBaseAggregationTimestamp(end);
				it = timeSeriesDatabase.store.getHistoryRange(plotID, startTime, endTime);
			} else {
				it = timeSeriesDatabase.store.getFreshestHistory(plotID, startTime);
			}
		} else {
			if(end!=null) {
				long endTime = BaseAggregationTimeUtil.calcMaxRawTimestampOfBaseAggregationTimestamp(end);
				it = timeSeriesDatabase.store.getHistoryRange(plotID, Long.MIN_VALUE, endTime);
			} else {
				it = timeSeriesDatabase.store.getHistory(plotID);
			}
		}		
		return baseAggregationProcessor.process(it);
	}
	
	public TimeSeries queryBaseAggregatedDataGapFilled(String [] querySensorNames, Long start, Long end) {
		TimeSeries timeseries = queryBaseAggregatedData(querySensorNames, start, end);
		//TODO		
		return timeseries;
	}
	
	/**
	 * Get raw sensor data
	 * @param querySensorNames sensors in the result schema; if null all available sensors are in the result schema
	 * @param start start time stamp, if null start from oldest data
	 * @param end end time stamp, if null get data up to newest data
	 * @return
	 */
	public TimeSeries queryRawData(String[] querySensorNames, Long start, Long end) {
		String[] schemaSensorNames = getLoggerType().sensorNames;
		RawDataProcessor rawDataProcessor = new RawDataProcessor(getLoggerType().sensorNames, querySensorNames);
		Iterator<Event> it;
		if(start!=null) {
			long startTime = start;
			if(end!=null) {
				long endTime = end;
				it = timeSeriesDatabase.store.getHistoryRange(plotID, startTime, endTime);
			} else {
				it = timeSeriesDatabase.store.getFreshestHistory(plotID, startTime);
			}
		} else {
			if(end!=null) {
				long endTime = end;
				it = timeSeriesDatabase.store.getHistoryRange(plotID, Long.MIN_VALUE, endTime);
			} else {
				it = timeSeriesDatabase.store.getHistory(plotID);
			}
		}		
		return rawDataProcessor.process(it);
	}
	
	@Override
	public String toString() {
		return plotID;
	}
}
