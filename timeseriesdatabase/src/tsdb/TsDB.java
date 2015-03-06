package tsdb;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Stream;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.aggregated.AggregationType;
import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.catalog.SourceCatalog;
import tsdb.graph.Aggregated;
import tsdb.graph.Base;
import tsdb.graph.Continuous;
import tsdb.graph.NodeGen;
import tsdb.graph.VirtualPlotStationBase;

/**
 * This is the main class of the timeseries database.
 * @author woellauer
 *
 */
public class TsDB {

	private static final Logger log = LogManager.getLogger();

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

	//Map PlotID -> Plot Object
	private Map<String,Plot> plotMap;


	//*** begin persistent information ***

	/**
	 * storage of all time series
	 */
	public StreamStorageStreamDB streamStorage;

	public CacheStorage cacheStorage;

	public SourceCatalog sourceCatalog; 


	//*** end persistent information ***



	/**
	 * create a new TimeSeriesDatabase object and connects to stored database files
	 * @param databasePath
	 * @param evenstoreConfigFile
	 * @param streamdbPathPrefix 
	 */
	public TsDB(String databasePath, String evenstoreConfigFile, String cachePath, String streamdbPathPrefix) {		
		log.info("open tsdb...");		

		this.regionMap = new TreeMap<String,Region>();

		//this.streamStorage = new StreamStorageEventStore(databasePath, evenstoreConfigFile);
		//this.streamStorage = new StreamStorageMapDB(databasePath);
		this.streamStorage = new StreamStorageStreamDB(streamdbPathPrefix);
		loggerTypeMap = new TreeMap<String, LoggerType>();
		stationMap = new TreeMap<String,Station>();
		generalStationMap = new TreeMap<String, GeneralStation>();
		sensorMap = new TreeMap<String,Sensor>();
		ignoreSensorNameSet = new TreeSet<String>();
		baseAggregationSensorNameSet = new TreeSet<String>();

		this.cacheStorage = new CacheStorage(cachePath);

		this.virtualplotMap = new TreeMap<String, VirtualPlot>();

		this.plotMap = new TreeMap<String,Plot>();

		this.sourceCatalog = new SourceCatalog(databasePath);
	}	

	/**
	 * clears all stream data in EventStore; deletes all database files
	 */
	public void clear() {
		cacheStorage.clear();
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
	public Sensor[] getSensors(String[] names) {
		Sensor[] sensors = new Sensor[names.length];
		for(int i=0;i<names.length;i++) {
			Sensor sensor = sensorMap.get(names[i]);
			sensors[i] = sensor;
			if(sensor==null) {
				log.warn("sensor "+names[i]+" not found");
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

	/**
	 * gets first and last timestamp of virtualplot or station
	 * @param stationName
	 * @return null if empty
	 */
	public long[] getTimeInterval(String stationName) {
		VirtualPlot virtualPlot = getVirtualPlot(stationName);
		if(virtualPlot!=null) {
			return virtualPlot.getTimestampInterval();
		}
		/*Iterator<Event> it = streamStorage.queryRawEvents(stationName, null, null);
		if(it==null || !it.hasNext()) {
			return null;
		}
		long start = it.next().getTimestamp();
		long end = start;
		while (it.hasNext()) {
			end = it.next().getTimestamp();
		}
		return new long[]{start,end};*/
		return streamStorage.getTimeInterval(stationName);
	}

	/**
	 * gets first and last timestamp of virtualplot or station
	 * @param stationName
	 * @return null if empty
	 */
	public long[] getBaseTimeInterval(String stationName) {
		long[] interval = getTimeInterval(stationName);
		if(interval==null) {
			return null;
		}
		return new long[]{BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(interval[0]),BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(interval[1])};
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

	public Stream<GeneralStation> getGeneralStations(String regionName) {
		return generalStationMap.values().stream().filter(x->regionName.equals(x.region.name));
	}

	public Set<String> getGeneralStationGroups() {
		Set<String> set = new TreeSet<String>();
		getGeneralStations().forEach(gs->set.add(gs.group));
		return set;
	}

	public Stream<String> getStationAndVirtualPlotNames(String group) {		
		return getGeneralStationsOfGroup(group).flatMap(gs->gs.getStationAndVirtualPlotNames());
	}

	public Stream<String> getPlotNames() {
		Stream<String> stationStream = stationMap.values().stream().filter(s->s.isPlot).map(s->s.stationID);
		Stream<String> virtualPlotStream = virtualplotMap.keySet().stream();
		return Stream.concat(stationStream,virtualPlotStream);
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

	public Stream<String> getRegionLongNames() {
		return regionMap.values().stream().map(x -> x.longName);
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



	public String[] getGeneralStationLongNames(String regionName) {
		return getGeneralStations(regionName).map(x -> x.longName).sorted().toArray(String[]::new);
	}

	//*********************************************** end Region *************************************************************************


	//*********************************************** begin base aggregation *************************************************************************

	public boolean baseAggregationExists(String sensorName) {
		return baseAggregationSensorNameSet.contains(sensorName);
	}

	public void insertBaseAggregation(String sensorName, AggregationType aggregateType) {
		Sensor sensor = getSensor(sensorName);
		if(sensor==null) {
			log.trace("created new sensor "+sensorName);
			sensor = new Sensor(sensorName);
			insertSensor(sensor);
		}			
		if(baseAggregationExists(sensorName)) {
			log.warn("base aggregation already exists: "+sensorName);
		} else {
			baseAggregationSensorNameSet.add(sensorName);
		}
		sensor.baseAggregationType = aggregateType;
	}

	public String[] getBaseSchema(String[] rawSchema) {
		ArrayList<String> sensorNames = new ArrayList<String>();
		for(String name:rawSchema) {
			if(this.baseAggregationExists(name)) {
				sensorNames.add(name);
			}
		}
		if(sensorNames.isEmpty()) {
			return null;
		}
		return sensorNames.toArray(new String[0]);
	}

	public Set<String> getBaseAggregationSensorNames() {
		return baseAggregationSensorNameSet;
	}
	
	public boolean isBaseSchema(String[] schema) {
		for(String sensorName:schema) {
			if(!baseAggregationSensorNameSet.contains(sensorName)) {
				return false;
			}
		}
		return true;
	}

	//*********************************************** end base aggregation *************************************************************************

	public String[] getValidSchema(String plotID, String[] schema) {
		VirtualPlot virtualPlot = getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return virtualPlot.getValidSchemaEntries(schema);
		}
		Station station = getStation(plotID);
		if(station!=null) {
			return station.getValidSchemaEntries(schema);
		}		
		String[] parts = plotID.split(":"); // structure plotID:stationID
		if(parts.length!=2) {
			throw new RuntimeException("plotID not found: "+plotID);
		}
		station = getStation(parts[1]);
		if(station!=null) {
			return station.getValidSchemaEntries(schema);
		}
		
		throw new RuntimeException("plotID not found: "+plotID);
	}

	public boolean isValidSchema(String plotID, String[] schema) {

		VirtualPlot virtualPlot = getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return virtualPlot.isValidSchema(schema);
		}
		Station station = getStation(plotID);
		if(station!=null) {
			return station.isValidSchema(schema);
		}
		throw new RuntimeException("plotID not found: "+plotID);
	}

	public void createPlotMap() {
		for(VirtualPlot virtualPlot:getVirtualPlots()) {
			if(!plotMap.containsKey(virtualPlot.plotID)) {
				plotMap.put(virtualPlot.plotID, new Plot(virtualPlot.plotID));
			} else {
				log.warn("plot exists already: "+virtualPlot.plotID);
			}
		}
		for(Station station:getStations()) {
			if(station.isPlot) {
				if(!plotMap.containsKey(station.stationID)) {
					plotMap.put(station.stationID, new Plot(station.stationID));
				} else {
					log.warn("plot exists already: "+station.stationID);
				}
			}
		}
	}

	/**
	 * Get an array of reference values of sensors at plotID.
	 * @param plotID
	 * @param schema
	 * @return
	 */
	public float[] getReferenceValues(String plotID, String[] schema) {
		float[] result = new float[schema.length];
		for(int i=0;i<result.length;i++) {
			result[i] = 0f;
		}
		VirtualPlot virtualPlot = getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			for(int i=0;i<schema.length;i++) {
				if(schema[i].equals("Ta_200")) {
					result[i] = virtualPlot.elevationTemperature;
				}
			}
		}
		return result;
	}
}
