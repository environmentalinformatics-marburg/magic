package timeseriesdatabase;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
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
import org.ini4j.BasicMultiMap;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import util.Table;
import util.Util;
import au.com.bytecode.opencsv.CSVReader;
import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.btree.TimeSplitBTreeEventStore;
import de.umr.jepc.util.enums.TimeRepresentation;

/**
 * This is the main class of the timeseries database.
 * @author Stephan Wöllauer
 *
 */
public class TimeSeriesDatabase {
	
	private static final Logger log = Util.log;
	
	public TimeSplitBTreeEventStore store;
	
	public Map<String,LoggerType> loggerTypeMap;
	
	public Map<String,Station> stationMap;
	
	public Map<String,GeneralStation> generalStationMap;
	
	public Map<String,Sensor> sensorMap;
	
	public Set<String> ignoreSensorNameSet;
	
	public Set<String> baseAggregatonSensorNameSet;
	
	public TimeSeriesDatabase(String databasePath, String evenstoreConfigFile) {
		
		log.trace("create TimeSeriesDatabase");
		
		FileInputStream configStream = null; 
		try {
			configStream = new FileInputStream(evenstoreConfigFile);
		} catch (FileNotFoundException e) {
			log.error(configStream);
		}
		
		//TimeSplitBTreeEventStore(TimeRepresentation representation, String databasePath, InputStream configStream)
		store = new TimeSplitBTreeEventStore(TimeRepresentation.POINT,databasePath,configStream);
		//store = new TimeSplitBTreeEventStore();
		
		loggerTypeMap = new HashMap<String, LoggerType>();
		stationMap = new HashMap<String,Station>();
		generalStationMap = new HashMap<String, GeneralStation>();
		sensorMap = new HashMap<String,Sensor>();
		ignoreSensorNameSet = new HashSet<String>();
		baseAggregatonSensorNameSet = new HashSet<String>(); 
		
		
		store.open();		
	}
	
	/**
	 * for each station type read schema of data, only data of names in this schema is included in the database
	 * This method creates LoggerType Objects
	 * @param configFile
	 */
	public void readLoggerSchemaConfig(String configFile) {
		//System.out.println("begin readLoggerSchemaConfig...");

		try {
		
		Wini ini = new Wini(new File(configFile));
		
		

		for(String typeName:ini.keySet()) {
			
			Section section = ini.get(typeName);
			List<String> names = new ArrayList<String>();			
			for(String name:section.keySet()) {
				names.add(name);
			}
			
			String[] sensorNames = new String[names.size()];
			Attribute[] schema = new Attribute[names.size()+1];
			for(int i=0;i<names.size();i++) {
				sensorNames[i] = names.get(i);
				schema[i] =  new Attribute(names.get(i),DataType.FLOAT);
			}
			schema[sensorNames.length] = new Attribute("sampleRate",DataType.SHORT);
						
			//System.out.println("create logger type: "+typeName);
			loggerTypeMap.put(typeName, new LoggerType(typeName, sensorNames,schema));
			
		}

		//System.out.println();
		
		} catch (Exception e) {
			System.out.println(e);
		}

		//System.out.println("...end");		
	}
	
	/**
	 * reads properties of stations and creates Station Objects
	 * @param configFile
	 */
	public void readStationConfig(String configFile) {
		Map<String,List<Map<String,String>>> plotIdMap = readStationConfigInternal(configFile);
		
		for(Entry<String, List<Map<String, String>>> entryMap:plotIdMap.entrySet()) {
			if(entryMap.getValue().size()!=1) {
				log.error("multiple properties for one station not implemented:\t"+entryMap.getValue());
			} else {
				String plotID = entryMap.getKey();
				String generalStationName = plotID.substring(0, 3);
				Station station = new Station(this, generalStationName, plotID, entryMap.getValue().get(0));
				stationMap.put(plotID, station);
			}
		}	
	}
	
	/**
	 * reads properties of stations
	 * @param configFile
	 */
	private static Map<String,List<Map<String,String>>> readStationConfigInternal(String config_file) {
		try {
			CSVReader reader = new CSVReader(new FileReader(config_file));
			List<String[]> list = reader.readAll();
			
			String[] names = list.get(0);
			
			final String NAN_TEXT = "NaN";
			
			Map<String,Integer> nameMap = new HashMap<String,Integer>();
			
			for(int i=0;i<names.length;i++) {
				if(!names[i].equals(NAN_TEXT)) {
					if(nameMap.containsKey(names[i])) {
						log.error("dublicate name: "+names[i]);
					} else {
						nameMap.put(names[i], i);
					}
				}
			}
			
			
			String[][] values = new String[list.size()-1][];
			
			for(int i=1;i<list.size();i++) {
				values[i-1] = list.get(i);
			}
			
			Map<String,List<Map<String,String>>> plotidMap = new HashMap<String,List<Map<String,String>>>();
			
			int plotidIndex = nameMap.get("PLOTID");
			for(String[] row:values) {
				String plotid = row[plotidIndex];
				List<Map<String,String>> entries = plotidMap.get(plotid);
				if(entries==null) {
					entries = new ArrayList<Map<String,String>>(1);
					plotidMap.put(plotid, entries);
				}				
				
				Map<String,String> valueMap = new HashMap<String, String>();
				for(Entry<String, Integer> mapEntry:nameMap.entrySet()) {
					
					String value = row[mapEntry.getValue()];
					if(!value.toUpperCase().equals(NAN_TEXT.toUpperCase())) {
						valueMap.put(mapEntry.getKey(), value);
					}					
				}
				
				entries.add(valueMap);
			}
			return plotidMap;			
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
		
		
	}
	
	/**
	 * Registers streams for all containing stations (with stream name == plotID)
	 */
	public void registerStreams() {
		System.out.println("register streams...");
		
		for(Station station:stationMap.values()) {
			//System.out.println(station.getLoggerType().schema+"\t"+station.plotID);
			store.registerStream(station.plotID, station.getLoggerType().schema);
		}
		
		System.out.println("...end");
	}
	
	/**
	 * clears all stream data in EventStore
	 */
	public void clear() {
		store.clear();
	}
	
	/**
	 * closed EventStore, all data is written to disk
	 */
	public void close() {
		store.close();
	}
	
	
	public void loadDirectoryOfOneExploratory(Path exploratoriyPath) {
		log.info("load exploratory:\t"+exploratoriyPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(exploratoriyPath);
			for(Path stationPath:stream) {
				String stationID = stationPath.subpath(stationPath.getNameCount()-1, stationPath.getNameCount()).toString();
				
				//*** workaround for directory names ***
				
				if(stationID.startsWith("HG")) {
					stationID = "HEG"+stationID.substring(2);
				} else if(stationID.startsWith("HW")) {
					stationID = "HEW"+stationID.substring(2);
				}
				
				//**********************************
				
				
				if(!stationMap.containsKey(stationID)) {
					log.error("station does not exist in database:\t"+stationID);
				} else {				
					Station station = stationMap.get(stationID);
					station.loadDirectoryOfOneStation(stationPath);
				}
			}
		} catch (IOException e) {
			log.error(e);
		}
		
	}
	
	/**
	 * creates a map of all entries in one section of an "ini"-file
	 * @param section
	 * @return
	 */
	private Map<String, String> readSensorNameMap(Section section) {
		Map<String,String> sensorNameMap = new HashMap<String, String>();
		for(String key:section.keySet()) {
			if(!key.equals("NaN")) {
				//System.out.println(key+" -> "+section.get(key));
				sensorNameMap.put(key, section.get(key));
			}
		}
		return sensorNameMap;
	}
	
	public void readSensorRangeConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("parameter_range");
			if(section!=null) {
				for(String key:section.keySet()) {
					String range = section.get(key);
					String minString = range.substring(range.indexOf('[')+1, range.indexOf(','));
					String maxString = range.substring(range.indexOf(',')+2, range.indexOf(']'));
					float min=Float.parseFloat(minString);
					float max=Float.parseFloat(maxString);
					//System.out.println("range "+key+"\t"+range+"\t("+min+")\t("+max+")");
					Sensor sensor = new Sensor(key);
					sensor.min = min;
					sensor.max = max;
					sensorMap.put(key, sensor);
				}
			}
		} catch (IOException e) {
			log.warn(e);
		}
	}
	
	public void readSensorNameTranslationConfig(String configFile) {
		
		final String SENSOR_NAME_CONVERSION_HEADER_SUFFIX = "_header_0000";
		
		try {
			Wini ini = new Wini(new File(configFile));

			for(LoggerType loggerType:loggerTypeMap.values()) {
				log.trace("read config for "+loggerType.typeName);
				Section section = ini.get(loggerType.typeName+SENSOR_NAME_CONVERSION_HEADER_SUFFIX);
				if(section!=null) {
					loggerType.sensorNameTranlationMap = readSensorNameMap(section);
				} else {
					log.warn("logger type name tranlation not found:\t"+loggerType.typeName);
				}
			}



			String suffix = "_soil_parameters_header_0000";

			for(Section section:ini.values()) {
				String sectionName = section.getName();


				//System.out.println("section: "+sectionName);

				for(GeneralStation generalStation:generalStationMap.values()) {
					String prefix = "000"+generalStation.name;
					if(sectionName.startsWith(prefix)) {
						String general_section = prefix+"xx"+suffix;
						if(sectionName.equals(general_section)) {
							generalStation.sensorNameTranlationMap = readSensorNameMap(section);
						} else if(sectionName.endsWith(suffix)) {
							String plotID = sectionName.substring(3, 8);
							Station station = stationMap.get(plotID);
							if(station!=null) {
								station.sensorNameTranlationMap = readSensorNameMap(section);
							} else {
								log.warn("station does not exist: "+plotID);
							}
						} else {
							log.warn("unknown: "+sectionName);
						}
					}				
				}
			}
		} catch (Exception e) {
			log.error(e);
		}
	}

	public void readGeneralStationConfig(String configFile) {
		//System.out.println("readGeneralStationConfig");
		try {
			BufferedReader reader = new BufferedReader(new FileReader(configFile));
			String next = reader.readLine();
			while(next!=null) {
				//System.out.println(next);
				generalStationMap.put(next, new GeneralStation(next));
				next = reader.readLine();
			}
			reader.close();
		} catch (FileNotFoundException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
		
	}

	public void readIgnoreSensorNameConfig(String configFile) {
		//System.out.println("readIgnoreSensorNameConfig");
		try {
			BufferedReader reader = new BufferedReader(new FileReader(configFile));
			String next = reader.readLine();
			while(next!=null) {
				//System.out.println(next);
				ignoreSensorNameSet.add(next);
				next = reader.readLine();
			}
			reader.close();
		} catch (FileNotFoundException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
		
	}
	
	public void readBaseAggregationConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("base_aggregation");
			if(section!=null) {
				for(String sensorName:section.keySet()) {
					Sensor sensor =sensorMap.get(sensorName);
					if(sensor!=null) {
						String aggregateTypeText = section.get(sensorName);
						AggregationType aggregateType = AggregationType.NONE;
						if(aggregateTypeText.toLowerCase().equals("average")) {
							aggregateType = AggregationType.AVERAGE;
						} else if(aggregateTypeText.toLowerCase().equals("sum")) {
							aggregateType = AggregationType.SUM;
						} else if(aggregateTypeText.toLowerCase().equals("maximum")) {
							aggregateType = AggregationType.MAXIMUM;							
						} else if(aggregateTypeText.toLowerCase().equals("average_wind_direction")) {
							aggregateType = AggregationType.AVERAGE_WIND_DIRECTION;
						} else if(aggregateTypeText.toLowerCase().equals("average_wind_velocity")) {
							aggregateType = AggregationType.AVERAGE_WIND_VELOCITY;							
							
						} else {
							log.warn("aggregate type unknown: "+aggregateTypeText+"\tin\t"+sensorName);
						}
						sensor.baseAggregationType = aggregateType;
						baseAggregatonSensorNameSet.add(sensorName);
					} else {
						log.warn("sensor not found: "+sensorName);
					}
				}
			}
		} catch (IOException e) {
			log.warn(e);
		}		
		
		
		
	}
	
	public void loadDirectoryOfAllExploratories(Path exploratoriesPath) {
		log.info("load exploratories:\t"+exploratoriesPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(exploratoriesPath);
			for(Path path:stream) {
				System.out.println(path);
				loadDirectoryOfOneExploratory(path);
			}
		} catch (IOException e) {
			log.error(e);
		}
		
	}

	public Iterator<Event> query(String sql) {
		return store.query(sql);		
	}
	
	public  Iterator<Event> queryTimeSeries(String PlotID, String ParameterName, long startTime, long endTime) {
		return store.getHistoryRange(PlotID, startTime, endTime);		
	}
	
	/**
	 * Get base aggregated data
	 * @param plotID
	 * @param querySensorNames sensors in the result schema; if null all available sensors are in the result schema
	 * @return
	 */
	public TimeSeries queryBaseAggregatedData(String plotID,String[] querySensorNames) {		
		Station station = stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return TimeSeries.EMPTY_TIMESERIES; 				
		}
		return station.queryBaseAggregatedData(querySensorNames,null,null);		
	}
	
	/**
	 * Get base aggregated data
	 * @param plotID
	 * @param querySensorNames sensors in the result schema; if null all available sensors are in the result schema
	 * @param start
	 * @param end
	 * @return
	 */
	public TimeSeries queryBaseAggregatedData(String plotID, String[] querySensorNames, Long start, Long end) {		
		Station station = stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return TimeSeries.EMPTY_TIMESERIES; 				
		}
		TimeSeries timeseries = station.queryBaseAggregatedData(querySensorNames, start, end);
		return timeseries;
	}
	
	
	public TimeSeries queryBaseAggregatedDataGapFilled(String plotID, String [] querySensorNames, Long start, Long end) {
		Station station = stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return TimeSeries.EMPTY_TIMESERIES; 				
		}
		TimeSeries ___timeseries = station.queryBaseAggregatedDataGapFilled(querySensorNames, start, end);
		
		TimeSeries gapTimeSeries = ___timeseries.getGapTimeSeries();
		
		final int STATION_INTERPOLATION_COUNT = 2;
		
		Station[] interpolationStations = new Station[STATION_INTERPOLATION_COUNT];
		for(int i=0;i<STATION_INTERPOLATION_COUNT;i++) {
			interpolationStations[i] = station.nearestStationList.get(i);
		}
		
		
		for(int parameterIndex=0;parameterIndex<gapTimeSeries.parameterNames.length;parameterIndex++) {
			System.out.println("gapfilling for: "+gapTimeSeries.parameterNames[parameterIndex]);
			for(int i=0;i<interpolationStations.length;i++) {
				interpolationStations[i].queryBaseAggregatedData(new String[]{gapTimeSeries.parameterNames[parameterIndex]}, null, null);
			}
			for(int rowIndex=0;rowIndex<gapTimeSeries.entryList.size();rowIndex++) {
				TimeSeriesEntry entry = gapTimeSeries.entryList.get(rowIndex);
				if(Float.isNaN(entry.data[parameterIndex])) {
					// TODO: interpolation
					entry.data[parameterIndex] = -99;
				}
			}
		}
		
		
		
		return gapTimeSeries;
	}
	
	
	public TimeSeries queryRawData(String plotID) {
		Station station = stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return TimeSeries.EMPTY_TIMESERIES; 				
		}
		return station.queryRawData(null,null,null);	
	}
	
	public TimeSeries queryRawData(String plotID, String[] querySensorNames) {
		Station station = stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return TimeSeries.EMPTY_TIMESERIES; 				
		}
		return station.queryRawData(querySensorNames,null,null);	
	}
	
	public TimeSeries queryRawData(String plotID, String[] querySensorNames, Long start,Long end) {
		Station station = stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return TimeSeries.EMPTY_TIMESERIES; 				
		}
		return station.queryRawData(querySensorNames,start,end);	
	}

	public Sensor[] getSensors(String[] sensorNames) {
		Sensor[] sensors = new Sensor[sensorNames.length];
		for(int i=0;i<sensorNames.length;i++) {
			Sensor sensor = sensorMap.get(sensorNames[i]);
			sensors[i] = sensor;
			if(sensor==null) {
				log.warn("sensor "+sensorNames+" not found");
			}
		}
		return sensors;
	}
	
	public void readStationGeoPositionConfig(String config_file) {

		try{
		
		Table table = Table.readCSV(config_file);
		
		int plotidIndex = table.getColumnIndex("PlotID");
		int epplotidIndex = table.getColumnIndex("EP_Plotid");
		int lonIndex = table.getColumnIndex("Lon");
		int latIndex = table.getColumnIndex("Lat");
		
		
		for(String[] row:table.rows) {
			String plotID = row[epplotidIndex];
			if(!plotID.endsWith("_canceled")) {
				Station station = stationMap.get(plotID);
				if(station!=null) {
					
					try {
					
					double lon = Double.parseDouble(row[lonIndex]);
					double lat = Double.parseDouble(row[latIndex]);
					
					station.geoPoslongitude = lon;
					station.geoPosLatitude = lat;
					
					GeneralStation generalStation = generalStationMap.get(station.generalStationName);
					if(generalStation!=null) {
					//System.out.println(station.generalStationName+": "+row[epplotidIndex]+"\t"+row[lonIndex]+"\t"+row[latIndex]);
					} else {
						log.warn("general station not found: "+station.generalStationName+" in "+plotID);
					}
					
					} catch(Exception e) {
						log.warn("geo pos not read: "+plotID);
					}
					
				} else {
					log.warn("station not found: "+row[epplotidIndex]+"\t"+row[lonIndex]+"\t"+row[latIndex]);
				}
			}
		}
		} catch(Exception e) {
			e.printStackTrace();
		}
		
		calcNearestStations();
		
	}
	
	public void updateGeneralStations() {
		
		for(GeneralStation g:generalStationMap.values()) {
			g.stationList = new ArrayList<Station>();
		}
		
		for(Station station:stationMap.values()) {
			generalStationMap.get(station.generalStationName).stationList.add(station);
		}
		
	}
	
	public void calcNearestStations() {
		updateGeneralStations();
		
		for(Station station:stationMap.values()) {
			
			
			double[] geoPos = transformCoordinates(station.geoPoslongitude,station.geoPosLatitude);
			
			List<Object[]> differenceList = new ArrayList<Object[]>();
			
			List<Station> stationList = generalStationMap.get(station.generalStationName).stationList;
			//System.out.println(station.plotID+" --> "+stationList);
			for(Station targetStation:stationList) {
				if(station!=targetStation) { // reference compare
					double[] targetGeoPos = transformCoordinates(targetStation.geoPoslongitude,targetStation.geoPosLatitude);
					double difference = getDifference(geoPos, targetGeoPos);
					differenceList.add(new Object[]{difference,targetStation});
				}
			}
			
			differenceList.sort(new Comparator<Object[]>() {

				@Override
				public int compare(Object[] o1, Object[] o2) {
					double d1 = (double) o1[0];
					double d2 = (double) o2[0];					
					return Double.compare(d1, d2);
				}
			});
			
			List<Station> targetStationList = new ArrayList<Station>(differenceList.size());
			for(Object[] targetStation:differenceList) {
				targetStationList.add((Station) targetStation[1]);
			}
			
			station.nearestStationList = targetStationList;
			//System.out.println(station.plotID+" --> "+station.nearestStationList);
		}
		
	}
	
	public static double[] transformCoordinates(double longitude, double latitude) {
		// TODO: do real transformation
		return new double[]{longitude,latitude};
	}
	
	public static double getDifference(double[] geoPos, double[] targetGeoPos) {
		return Math.sqrt((geoPos[0]-targetGeoPos[0])*(geoPos[0]-targetGeoPos[0])+(geoPos[1]-targetGeoPos[1])*(geoPos[1]-targetGeoPos[1]));
	}

}
