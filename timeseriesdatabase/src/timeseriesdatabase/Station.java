package timeseriesdatabase;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

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
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(stationPath, x -> x.toString().endsWith(".dat"));
			for(Path path:stream) {
				try {
				loadUDBFFile(path);
				} catch (Exception e) {
					log.error("file not read: "+path+"\t"+e);
				}
			}
			timeSeriesDatabase.store.flushStream(plotID);
		} catch (IOException e) {
			e.printStackTrace();
		}
		insertedTimestampSet = null; // *** duplicate workaround
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
		Attribute[] schema = loggerType.schema;
		for(Attribute attribue:schema) {
			if(attribue.getAttributeName().equals(sensorName)) {
				return sensorName;
			}
		}
		return null;
	}
	
	public void loadUDBFFile(Path filename) throws IOException {
		log.trace("load UDBF file:\t"+filename+"\tplotID:\t"+plotID);
		
		UniversalDataBinFile udbFile = new UniversalDataBinFile(filename);
		UDBFTimeSeries udbfTimeSeries = udbFile.getUDBFTimeSeries();
		udbFile.close();
		
		SensorHeader[] sensorHeaders = udbfTimeSeries.sensorHeaders;
		
		int[] eventPos = new int[sensorHeaders.length];
		Attribute[] schema = getLoggerType().schema;
		
		ArrayList<String> list = new ArrayList<String>();
		for(Attribute attribute:schema) {
			list.add(attribute.getAttributeName());
		}
		//System.out.println(getLoggerType().typeName+" schema: "+list);
		
		for(int sensorIndex=0; sensorIndex<sensorHeaders.length; sensorIndex++) {
			eventPos[sensorIndex] = -1;
			SensorHeader sensorHeader = sensorHeaders[sensorIndex];
			String rawSensorName = sensorHeader.name;
			if(!timeSeriesDatabase.ignoreSensorNameSet.contains(rawSensorName)) {
				String sensorName = translateInputSensorName(rawSensorName);
				//System.out.println(sensorHeader.name+"->"+sensorName);
				if(sensorName != null) {
					for(int schemaIndex=0;schemaIndex<schema.length;schemaIndex++) {
						Attribute attribute = schema[schemaIndex];
						if(attribute.getAttributeName().equals(sensorName)) {
							eventPos[sensorIndex] = schemaIndex;
						}
					}
				}
				if(eventPos[sensorIndex] == -1) {
					if(sensorName==null) {
						log.warn("sensor name not in translation map: "+rawSensorName+" -> "+sensorName+"\t"+plotID+"\t"+filename+"\t"+propertyMap.get("LOGGER"));
					} else {
						log.trace("sensor name not in schema: "+rawSensorName+" -> "+sensorName+"\t"+plotID+"\t"+filename+"\t"+propertyMap.get("LOGGER"));
					}
				}
			}
		}
		
		try {
		
		int[] sensorPos = new int[schema.length];
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
			log.trace("no fitting sensors in "+filename);
			return;
		}
		
		
		float[] min = new float[schema.length];
		float[] max = new float[schema.length];
		
		for(int i=0;i<schema.length;i++) {
			Sensor sensor = timeSeriesDatabase.sensorMap.get(schema[i].getAttributeName());
			if(sensor!=null) {
				min[i] = sensor.min;
				max[i] = sensor.max;
			} else {
				min[i] = -Float.MAX_VALUE;
				max[i] = Float.MAX_VALUE;
			}
		}

		//Float[] payload = new Float[schema.length];
		Object[] payload = new Object[schema.length];
		for(int rowIndex=0;rowIndex<udbfTimeSeries.time.length;rowIndex++) {
			float[] row = udbfTimeSeries.data[rowIndex];
			for(int attrNr=0;attrNr<schema.length;attrNr++) {
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
				System.out.println("write time 58508670 in "+plotID+"\t"+filename);
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
			
			if(insertedTimestampSet!=null) {
				if(!insertedTimestampSet.contains(timestamp)) {
					timeSeriesDatabase.store.pushEvent(plotID, payload, timestamp);
					insertedTimestampSet.add(timestamp);
				}
			} else {			
				timeSeriesDatabase.store.pushEvent(plotID, payload, timestamp);
			}
			
		}
		
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		
	
	}	

}
