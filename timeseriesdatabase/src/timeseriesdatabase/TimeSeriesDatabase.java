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
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.BasicMultiMap;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;
import org.ini4j.spi.BeanAccess;

import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.aggregated.Interpolator;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.catalog.SourceCatalog;
import timeseriesdatabase.loader.ASCTimeSeries;
import timeseriesdatabase.loader.KiLiCSV;
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
	 * map regionName -> Region
	 */
	private Map<String,Region> regionMap;	

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
	private Map<String,GeneralStation> generalStationMap;

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
	private Set<String> baseAggregationSensorNameSet;



	private Map<String,VirtualPlot> virtualplotMap;


	//*** begin persistent information ***

	/**
	 * EventStore is the storage of all time series
	 */
	public StreamStorage streamStorage;

	public CacheStorage cacheStorage;

	public SourceCatalog sourceCatalog; 


	//*** end persistent information ***



	/**
	 * create a new TimeSeriesDatabase object and connects to stored database files
	 * @param databasePath
	 * @param evenstoreConfigFile
	 */
	public TimeSeriesDatabase(String databasePath, String evenstoreConfigFile, String cachePath) {		
		log.trace("create TimeSeriesDatabase");		

		this.regionMap = new TreeMap<String,Region>();

		this.streamStorage = new StreamStorageEventStore(databasePath, evenstoreConfigFile);
		//this.streamStorage = new StreamStorageMapDB(databasePath);
		loggerTypeMap = new TreeMap<String, LoggerType>();
		stationMap = new TreeMap<String,Station>();
		generalStationMap = new TreeMap<String, GeneralStation>();
		sensorMap = new TreeMap<String,Sensor>();
		ignoreSensorNameSet = new TreeSet<String>();
		baseAggregationSensorNameSet = new TreeSet<String>();

		this.cacheStorage = new CacheStorage(cachePath);

		this.virtualplotMap = new TreeMap<String, VirtualPlot>();

		this.sourceCatalog = new SourceCatalog(databasePath);
	}	

	/**
	 * registers streams for all containing stations (with stream name == plotID)
	 */
	public void registerStreams() {
		for(Station station:getStations()) {
			if(station.loggerType!=null) {
				log.info("register stream "+station.stationID+" with schema of "+station.loggerType.typeName);
				streamStorage.registerStream(station.stationID, station.loggerType.schema);
			} else {
				log.error("stream not registered: "+station.stationID+"   logger type not found");
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
		try {
			streamStorage.close();
		} catch(Exception e) {
			log.error("error in streamStorage.close: "+e);
		}
		try {
			cacheStorage.close();
		}  catch(Exception e) {
			log.error("error in cacheStorage.close: "+e);
		}
		try {
			sourceCatalog.close();
		} catch(Exception e) {
			log.error("error in sourceCatalog.close: "+e);
		}
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

	public void updateGeneralStations() {

		for(GeneralStation g:getGeneralStations()) {
			g.stationList = new ArrayList<Station>();
			g.virtualPlots = new ArrayList<VirtualPlot>();
		}

		for(Station station:getStations()) {
			if(station.generalStation!=null) {
				GeneralStation generalStation = station.generalStation;
				if(generalStation!=null) {
					generalStation.stationList.add(station);
				} else {
					log.warn("no general station in "+station.stationID);
				}
			}
		}

		for(VirtualPlot virtualplot:virtualplotMap.values()) {
			if(virtualplot.generalStation!=null) {
				virtualplot.generalStation.virtualPlots.add(virtualplot);
			} else {
				log.warn("no general station in "+virtualplot.plotID);
			}

		}
	}

	//*********************************************** begin Station *************************************************

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
		if(stationMap.containsKey(station.stationID)) {
			log.warn("override station (already exists): "+station.stationID);
		}
		stationMap.put(station.stationID, station);
	}

	public long getFirstTimestamp(String stationID) {
		Iterator<Event> it = streamStorage.queryRawEvents(stationID, null, null);
		if(it.hasNext()) {
			return it.next().getTimestamp();
		} else {
			return -1;
		}
	}

	public long getLastTimestamp(String stationID) {
		Iterator<Event> it = streamStorage.queryRawEvents(stationID, null, null);
		long timestamp = -1;
		while (it.hasNext()) {
			timestamp = it.next().getTimestamp();
		}
		return timestamp;
	}

	public long getFirstTimestampBaseAggregated(String stationID) {
		return BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(getFirstTimestamp(stationID));
	}

	public long getLastTimestampBaseAggregated(String stationID) {
		return BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(getLastTimestamp(stationID));
	}

	//*********************************************** end Station *************************************************

	//*********************************************** begin GeneralStation *************************************************

	public boolean generalStationExists(String generalStationName) {
		return generalStationMap.containsKey(generalStationName);
	}

	public void insertGeneralStation(GeneralStation generalStation) {
		if(generalStationExists(generalStation.name)) {
			log.warn("override general station (already exists): "+generalStation.name);
		}
		generalStationMap.put(generalStation.name, generalStation);
	}

	public Collection<GeneralStation> getGeneralStations() {
		return generalStationMap.values();
	}
	
	public Stream<GeneralStation> getGeneralStationsOfGroup(String group) {
		return generalStationMap.values().stream().filter(gs -> group.equals(gs.group));
	}

	public GeneralStation getGeneralStation(String generalStationName) {
		return generalStationMap.get(generalStationName);
	}

	public GeneralStation getGeneralStationByLongName(String longName) {
		for(GeneralStation generalStaion:generalStationMap.values()) {
			if(generalStaion.longName.equals(longName)) {
				return generalStaion;
			}
		}
		return null;
	}

	public String[] getGeneralStationNames() {
		return generalStationMap.keySet().stream().toArray(String[]::new);
	}

	public Stream<GeneralStation> getGeneralStations(Region region) {
		return generalStationMap.values().stream().filter(x->x.region==region);
	}

	//*********************************************** end GeneralStation *************************************************

	//*********************************************** begin Sensor *******************************************************

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

	//*********************************************** end Sensor **********************************************************

	//*********************************************** begin LoggerType *******************************************************

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

	//*********************************************** begin VirtualPlot *******************************************************

	public boolean virtualPlotExists(String plotID) {
		return virtualplotMap.containsKey(plotID);
	}

	public void insertVirtualPlot(VirtualPlot virtualPlot) {
		if(virtualPlotExists(virtualPlot.plotID)) {
			log.warn("overwrite virtual plot (already exists): "+virtualPlot.plotID);
		}
		virtualplotMap.put(virtualPlot.plotID, virtualPlot);
	}

	public VirtualPlot getVirtualPlot(String plotID) {
		return virtualplotMap.get(plotID);
	}

	public Collection<VirtualPlot> getVirtualPlots() {
		return virtualplotMap.values();
	}

	//*********************************************** end VirtualPlot *********************************************************

	//*********************************************** begin ignore sensor names *******************************************************

	public boolean containsIgnoreSensorName(String sensorName) {
		return ignoreSensorNameSet.contains(sensorName);
	}

	public void insertIgnoreSensorName(String sensorName) {
		if(containsIgnoreSensorName(sensorName)) {
			log.warn("sensor name already ignored: "+sensorName);
		}
		ignoreSensorNameSet.add(sensorName);
	}

	//*********************************************** end ignore sensor names *******************************************************




	//*********************************************** begin Region *******************************************************************

	public boolean regionExists(String regionName) {
		return regionMap.containsKey(regionName);
	}

	public void insertRegion(Region region) {
		if(regionExists(region.name)) {
			log.warn("overwrite region (already exists): "+region.name);
		}
		regionMap.put(region.name, region);
	}

	public Collection<Region> getRegions() {
		return regionMap.values();
	}

	public Set<String> getRegionNames() {
		return regionMap.keySet();
	}

	public String[] getRegionLongNames() {
		return regionMap.values().stream().map(x -> x.longName).toArray(String[]::new);
	}

	/**
	 * slow method
	 * @param longName
	 * @return 
	 */
	public Region getRegionByLongName(String longName) {
		for(Region region:regionMap.values()) {
			if(region.longName.equals(longName)) {
				return region;
			}
		}
		return null;
	}

	public Region getRegion(String regionName) {
		return regionMap.get(regionName);
	}



	public String[] getGeneralStationLongNames(Region region) {
		return getGeneralStations(region).map(x -> x.longName).sorted().toArray(String[]::new);
	}

	//*********************************************** end Region *************************************************************************


	//*********************************************** begin base aggregation *************************************************************************

	public boolean baseAggregationExists(String sensorName) {
		return baseAggregationSensorNameSet.contains(sensorName);
	}

	public void insertBaseAggregation(String sensorName, AggregationType aggregateType) {
		Sensor sensor = getSensor(sensorName);
		if(sensor!=null) {
			if(baseAggregationExists(sensorName)) {
				log.warn("base aggregation already exists: "+sensorName);
			} else {
				baseAggregationSensorNameSet.add(sensorName);
			}
			sensor.baseAggregationType = aggregateType;
		} else {
			log.warn("sensor does not exist; base aggregation not inserted: "+sensorName);
		}
	}

	public String[] getBaseAggregationSchema(String[] rawSchema) {
		ArrayList<String> sensorNames = new ArrayList<String>();
		for(String name:rawSchema) {
			if(this.baseAggregationExists(name)) {
				sensorNames.add(name);
			}
		}
		return sensorNames.toArray(new String[0]);
	}

	//*********************************************** end base aggregation *************************************************************************

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


}
