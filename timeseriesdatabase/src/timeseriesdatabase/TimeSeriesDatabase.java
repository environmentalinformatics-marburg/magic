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
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.EventListener;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.BasicMultiMap;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.aggregated.Interpolator;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.catalog.SourceCatalog;
import timeseriesdatabase.raw.CSVTimeSeries;
import timeseriesdatabase.raw.KiLiCSV;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Table;
import util.TimeSeriesSchema;
import util.TimestampInterval;
import util.Util;
import util.Util.FloatRange;
import util.iterator.SchemaIterator;
import au.com.bytecode.opencsv.CSVReader;
import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.btree.TimeSplitBTreeEventStore;
import de.umr.jepc.util.enums.TimeRepresentation;

/**
 * This is the main class of the timeseries database.
 * @author woellauer
 *
 */
public class TimeSeriesDatabase {

	private static final Logger log = Util.log;

	/**
	 * EventStore is the storage of all time series
	 */
	public StreamStorage streamStorage;

	/**
	 * station/logger type name	->	LoggerType Object
	 * 00CEMU, ...
	 */
	private Map<String,LoggerType> loggerTypeMap;

	/**
	 * plot id	->	Station Object
	 * HEG01, ...
	 */
	private Map<String,Station> stationMap;

	/**
	 * general station name	->	GeneralStation Object
	 * HEG, HEW, ...
	 */
	public Map<String,GeneralStation> generalStationMap;

	/**
	 * sensor name	->	Sensor Object
	 * Ta_200, ...
	 */
	private Map<String,Sensor> sensorMap;

	/**
	 * set of sensor names of input files, that should not be stored in database
	 */
	private Set<String> ignoreSensorNameSet;

	/**
	 * set of sensor name, that should be included in base aggregation processing
	 */
	public Set<String> baseAggregationSensorNameSet;

	public CacheStorage cacheStorage;

	private Map<String,VirtualPlot> virtualplotMap; // TODO change
	
	public SourceCatalog sourceCatalog; 

	/**
	 * create a new TimeSeriesDatabase object and connects to stored database files
	 * @param databasePath
	 * @param evenstoreConfigFile
	 */
	public TimeSeriesDatabase(String databasePath, String evenstoreConfigFile, String cachePath) {		
		log.trace("create TimeSeriesDatabase");		

		this.streamStorage = new StreamStorageEventStore(databasePath, evenstoreConfigFile);
		//this.streamStorage = new StreamStorageMapDB(databasePath);
		loggerTypeMap = new HashMap<String, LoggerType>();
		stationMap = new TreeMap<String,Station>();
		generalStationMap = new HashMap<String, GeneralStation>();
		sensorMap = new TreeMap<String,Sensor>();
		ignoreSensorNameSet = new HashSet<String>();
		baseAggregationSensorNameSet = new HashSet<String>();

		this.cacheStorage = new CacheStorage(cachePath);

		this.virtualplotMap = new TreeMap<String, VirtualPlot>();
		
		this.sourceCatalog = new SourceCatalog(databasePath);
	}

	public Attribute[] createAttributes(String[] names) {
		Attribute[] result = new Attribute[names.length];
		for(int i=0;i<names.length;i++) {
			result[i] = new Attribute(names[i],DataType.FLOAT);
		}
		return result;
	}

	static String loggerPropertyKiLiToLoggerName(String s) {
		if((s.charAt(0)>='0'&&s.charAt(0)<='9')&&(s.charAt(1)>='0'&&s.charAt(1)<='9')&&(s.charAt(2)>='0'&&s.charAt(2)<='9')){
			return s.substring(3);
		} else {
			return s;
		}
	}

	private static String plotIdKiLiToGeneralStationName(String s) {
		if(s.length()==4&&s.charAt(3)>='0'&&s.charAt(3)<='9') {
			return s.substring(0, 3);
		} else {
			return s; // not general station
		}
	}

	/**
	 * reads properties of stations
	 * @param configFile
	 */
	static Map<String, List<StationProperties>> readKiLiStationConfigInternal(String config_file) {  //  KiLi
		try {
			CSVReader reader = new CSVReader(new FileReader(config_file));
			List<String[]> list = reader.readAll();			
			String[] names = list.get(0);			
			final String NAN_TEXT = "NaN";			
			Map<String,Integer> nameMap = new HashMap<String,Integer>(); // map: header name -> column index			
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



			Map<String,List<StationProperties>> serialMap = new HashMap<String,List<StationProperties>>();
			int serialIndex = nameMap.get("SERIAL");
			for(String[] row:values) {
				String serial = row[serialIndex];

				List<StationProperties> mapList = serialMap.get(serial);
				if(mapList==null) {
					mapList = new ArrayList<StationProperties>(1);
					serialMap.put(serial, mapList);
				}

				HashMap<String, String> properyMap = new HashMap<String,String>();

				for(Entry<String, Integer> mapEntry:nameMap.entrySet()) {
					String value = row[mapEntry.getValue()];
					//if(!value.toUpperCase().equals(NAN_TEXT.toUpperCase())) {// ?? Nan should be in property map
					properyMap.put(mapEntry.getKey(), value);
					//}					
				}				
				mapList.add(new StationProperties(properyMap));
			}
			reader.close();
			return serialMap;			
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * registers streams for all containing stations (with stream name == plotID)
	 */
	public void registerStreams() {
		for(Station station:getStations()) {
			if(station.loggerType!=null) {
				log.info("register stream "+station.plotID+" with schema of "+station.loggerType.typeName);
				streamStorage.registerStream(station.plotID, station.loggerType.schema);
			} else {
				log.error("stream not registered: "+station.plotID+"   logger type not found");
			}
		}
	}

	/**
	 * clears all stream data in EventStore; deletes all database files
	 */
	public void clear() {
		sourceCatalog.clear();		
		streamStorage.clear();
	}

	/**
	 * close EventStore, all pending stream data is written to disk
	 */
	public void close() {
		streamStorage.close();
		//store.close();
	}	

	public Float[] getEmpiricalDiff(String[] schema) {
		Float[] diff = new Float[schema.length];
		for(int i=0;i<schema.length;i++) {
			Sensor sensor = sensorMap.get(schema[i]);
			if(sensor!=null) {
				diff[i] = sensor.empiricalDiff;
			} else {
				throw new RuntimeException("sensor not found: "+schema[i]);
			}
		}
		return diff;
	}

	/**
	 * get array of Sensor objects with given sensor names
	 * @param outputTimeSeriesSchema
	 * @return
	 */
	public Sensor[] getSensors(TimeSeriesSchema outputTimeSeriesSchema) {
		Sensor[] sensors = new Sensor[outputTimeSeriesSchema.columns];
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			Sensor sensor = sensorMap.get(outputTimeSeriesSchema.schema[i]);
			sensors[i] = sensor;
			if(sensor==null) {
				log.warn("sensor "+outputTimeSeriesSchema+" not found");
			}
		}
		return sensors;
	}

	/*public void readKiLiStationGeoPositionConfig(String config_file) {  //TODO
		try{		
			Table table = Table.readCSV(config_file);		
			int plotidIndex = table.getColumnIndex("PlotID");
			int epplotidIndex = table.getColumnIndex("EP_Plotid"); 
			int lonIndex = table.getColumnIndex("Lon");
			int latIndex = table.getColumnIndex("Lat");			
			for(String[] row:table.rows) {
				String plotID = row[epplotidIndex];
				if(!plotID.endsWith("_canceled")) { // ignore plotid canceled positions
					Station station = stationMap.get(plotID);
					if(station!=null) {					
						try {					
							double lon = Double.parseDouble(row[lonIndex]);
							double lat = Double.parseDouble(row[latIndex]);					
							station.geoPoslongitude = lon;
							station.geoPosLatitude = lat;					
						} catch(Exception e) {
							log.warn("geo pos not read: "+plotID);
						}
						if(plotidIndex>-1) {
							station.serialID = row[plotidIndex];
						}
					} else {
						log.warn("station not found: "+row[epplotidIndex]+"\t"+row[lonIndex]+"\t"+row[latIndex]);
					}
				}

			}

		} catch(Exception e) {
			log.error(e);
		}		
		calcNearestStations();		
	}*/

	public void updateGeneralStations() {

		for(GeneralStation g:generalStationMap.values()) {
			g.stationList = new ArrayList<Station>();
			g.virtualPlotList = new ArrayList<VirtualPlot>();
		}

		for(Station station:getStations()) {
			if(station.generalStationName!=null) {
				GeneralStation generalStation = generalStationMap.get(station.generalStationName);
				if(generalStation!=null) {
					generalStation.stationList.add(station);
				} else {
					log.warn("general station not found: "+station.generalStationName+" in "+station.plotID);
				}
			}
		}

		for(VirtualPlot virtualplot:virtualplotMap.values()) {
			if(virtualplot.generalStationName!=null) {
				GeneralStation generalStation = generalStationMap.get(virtualplot.generalStationName);
				if(generalStation!=null) {
					generalStation.virtualPlotList.add(virtualplot);
				} else {
					log.warn("general station not found: "+virtualplot.generalStationName+" in "+virtualplot.plotID);
				}
			}
		}
	}

	public Station getStation(String stationName) {
		return stationMap.get(stationName);		
	}
	
	public Collection<Station> getStations() {
		return stationMap.values();
	}
	
	public Set<String> getStationNames() {
		return stationMap.keySet();
	}
	
	public boolean stationExists(String stationName) {
		return stationMap.containsKey(stationName);
	}
	
	public void insertStation(Station station) {
		if(stationMap.containsKey(station.plotID)) {
			log.warn("override station (already exists): "+station.plotID);
		}
		stationMap.put(station.plotID, station);
	}

	public long getFirstTimestamp(String plotID) {
		Iterator<Event> it = streamStorage.queryRawEvents(plotID, null, null);
		if(it.hasNext()) {
			return it.next().getTimestamp();
		} else {
			return -1;
		}
	}

	public long getLastTimestamp(String plotID) {
		Iterator<Event> it = streamStorage.queryRawEvents(plotID, null, null);
		long timestamp = -1;
		while (it.hasNext()) {
			timestamp = it.next().getTimestamp();
		}
		return timestamp;
	}

	public long getFirstTimestampBaseAggregated(String plotID) {
		return BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(getFirstTimestamp(plotID));
	}

	public long getLastTimestampBaseAggregated(String plotID) {
		return BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(getLastTimestamp(plotID));
	}

	public String[] getBaseAggregationSchema(String[] rawSchema) {
		ArrayList<String> sensorNames = new ArrayList<String>();
		for(String name:rawSchema) {
			if(baseAggregationSensorNameSet.contains(name)) {
				sensorNames.add(name);
			}
		}
		return sensorNames.toArray(new String[0]);
	}

	public String[] getValidSchema(String stationID, String[] schema) {
		ArrayList<String> sensorNames = new ArrayList<String>();
		Map<String, Integer> map = Util.stringArrayToMap(getStation(stationID).loggerType.sensorNames);
		for(String name:schema) {
			if(map.containsKey(name)) {
				sensorNames.add(name);
			}
		}
		return sensorNames.toArray(new String[0]);
	}
	
	public boolean generalStationExists(String generalStationName) {
		return generalStationMap.containsKey(generalStationName);
	}
	
	public void insertGeneralStation(GeneralStation generalStation) {
		if(generalStationExists(generalStation.name)) {
			log.warn("override general station (already exists): "+generalStation.name);
		}
		generalStationMap.put(generalStation.name, generalStation);
	}
	
	public Collection<GeneralStation> getGeneralStaions() {
		return generalStationMap.values();
	}
	
	public GeneralStation getGeneralStation(String generalStationName) {
		return generalStationMap.get(generalStationName);
	}
	
	public boolean sensorExists(String sensorName) {
		return sensorMap.containsKey(sensorName);
	}
	
	public void insertSensor(Sensor sensor) {
		if(sensorExists(sensor.name)) {
			log.warn("override sensor (already exists): "+sensor.name);
		}
		sensorMap.put(sensor.name, sensor);
	}
	
	public Sensor getSensor(String sensorName) {
		return sensorMap.get(sensorName);
	}
	
	public Collection<Sensor> getSensors() {
		return sensorMap.values();
	}
	
	public boolean loggerTypeExists(String loggerTypeName) {
		return loggerTypeMap.containsKey(loggerTypeName);
	}
	
	public void insertLoggerType(LoggerType loggertype) {
		if(loggerTypeExists(loggertype.typeName)) {
			log.warn("override logger type (already exists): "+loggertype.typeName);
		}
		loggerTypeMap.put(loggertype.typeName, loggertype);
	}
	
	public LoggerType getLoggerType(String loggerTypeName) {
		return loggerTypeMap.get(loggerTypeName);
	}
	
	public Collection<LoggerType> getLoggerTypes() {
		return loggerTypeMap.values();
	}
	
	public boolean virtualPlotExists(String plotID) {
		return virtualplotMap.containsKey(plotID);
	}
	
	public void insertVirtualPlot(VirtualPlot virtualPlot) {
		if(virtualPlotExists(virtualPlot.plotID)) {
			log.warn("override virtual plot (already exists): "+virtualPlot.plotID);
		}
		virtualplotMap.put(virtualPlot.plotID, virtualPlot);
	}
	
	public VirtualPlot getVirtualPlot(String plotID) {
		return virtualplotMap.get(plotID);
	}
	
	public Collection<VirtualPlot> getVirtualPlots() {
		return virtualplotMap.values();
	}
	
	public boolean containsIgnoreSensorName(String sensorName) {
		return ignoreSensorNameSet.contains(sensorName);
	}
	
	public void insertIgnoreSensorName(String sensorName) {
		if(containsIgnoreSensorName(sensorName)) {
			log.warn("sensor name already ignored: "+sensorName);
		}
		ignoreSensorNameSet.add(sensorName);
	}
	
	public boolean isContainedInBaseAggregation(String sensorName) {
		return baseAggregationSensorNameSet.contains(sensorName);
	}
	

}
