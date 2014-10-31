package tsdb.streamdb;
import java.io.File;
import java.util.ArrayList;
import java.util.NavigableSet;
import java.util.TreeSet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mapdb.BTreeKeySerializer;
import org.mapdb.BTreeMap;
import org.mapdb.DB;
import org.mapdb.DBMaker;

import tsdb.streamdb.SensorMeta.ChunkMetaEntry;
import tsdb.util.iterator.TsIterator;


public class StreamDB {
	
	private static final Logger log = LogManager.getLogger();

	private DB db;

	private static final String DB_NAME_STATION_MAP = "stationMap";
	
	private BTreeMap<String,StationMeta> stationMetaMap;

	public StreamDB() {
		db = DBMaker.newFileDB(new File("c:/timeseriesdatabase_storage/db"))
				.compressionEnable()
				//.transactionDisable()
				//.mmapFileEnable() //slow commit and close!!!
				.mmapFileEnablePartial()
				.asyncWriteEnable()
				.asyncWriteFlushDelay(500)
				//.cacheSize(100000)
				.cacheSize(1000000)
				.closeOnJvmShutdown()
				.make();

		stationMetaMap = db.createTreeMap(DB_NAME_STATION_MAP)
				           .keySerializer(BTreeKeySerializer.STRING)
				           .valueSerializer(StationMeta.SERIALIZER)
				           .makeOrGet();		
	}
	
	public void commit() {
		synchronized (db) {
			if(!db.isClosed()) {
				db.commit();		
			}
		}
	}

	public void close() {
		synchronized (db) {
			if(!db.isClosed()) {
				log.info("commit...");
				db.commit();
				log.info("close...");
				db.close();
				log.info("closed");
			}
		}		
	}

	@Override
	protected void finalize() throws Throwable {
		close();
	}
	
	public void insertData(String stationName, String sensorName, ArrayList<DataEntry> data) {
		StationMeta stationMeta = stationMetaMap.get(stationName);
		BTreeMap<String, SensorMeta> sensorMap;
		if(stationMeta==null){
			stationMeta = new StationMeta(stationName);
			stationMetaMap.put(stationName, stationMeta);			
			sensorMap = db.createTreeMap(stationMeta.db_name_sensor_map)
			        .keySerializer(BTreeKeySerializer.STRING)
			        .valueSerializer(SensorMeta.SERIALIZER)
			        .makeOrGet();
		} else {
			sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);
		}
		
		SensorMeta sensorMeta = sensorMap.get(sensorName);
		BTreeMap<Integer, ArrayList<DataEntry>> sensorChunkMap;
		if(sensorMeta==null) {
			sensorMeta = new SensorMeta(stationName, sensorName);
			sensorMap.put(sensorName, sensorMeta);
			sensorChunkMap = db.createTreeMap(sensorMeta.db_name_sensor_chunk_map)
			        .keySerializer(BTreeKeySerializer.ZERO_OR_POSITIVE_INT)
			        .valueSerializer(DataEntry.CHUNK_SERIALIZER_DELTA_TIME_DELTA_INT_VALUE)
			        .valuesOutsideNodesEnable()
			        .makeOrGet();			
		} else {
			sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);
		}
		
				
		
		sensorChunkMap.put(data.get(0).timestamp, data);
		sensorMeta.list.add(new ChunkMetaEntry(data.get(0).timestamp,data.get(data.size()-1).timestamp));
		sensorMap.put(sensorName, sensorMeta);
	}
	
	public ArrayList<DataEntry> readData(String stationName, String sensorName) {
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		if(stationMeta==null){
			log.error("no station");
			return new ArrayList<DataEntry>();
		}
		
		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);		
		SensorMeta sensorMeta = sensorMap.get(sensorName);
		if(sensorMeta==null) {
			log.error("no sensor");
			return new ArrayList<DataEntry>();
		}
		
		BTreeMap<Integer, ArrayList<DataEntry>> sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);

		
		for(ArrayList<DataEntry> chunk:sensorChunkMap.values()) {
			return chunk;
		}
		return new ArrayList<DataEntry>();
	}
	
	public NavigableSet<String> getStationNames() {
		return stationMetaMap.keySet();
	}
	
	public NavigableSet<String> getSensorNames(String stationName) {
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		if(stationMeta==null){
			log.error("no station");
			return new TreeSet<String>();
		}
		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);
		return sensorMap.keySet();
	}
	
	public StreamIterator getSensorIterator(String stationName, String sensorName, int minTimestamp, int maxTimestamp) {
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		if(stationMeta==null){
			throw new RuntimeException("no station: "+stationName);
		}
		
		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);		
		SensorMeta sensorMeta = sensorMap.get(sensorName);
		if(sensorMeta==null) {
			throw new RuntimeException("no sensor: "+stationName+":   "+sensorName);
		}
		
		BTreeMap<Integer, ArrayList<DataEntry>> sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);

		return new StreamIterator(sensorMeta, sensorChunkMap, minTimestamp, maxTimestamp);	
	}
	
	public TsIterator getTsIterator(String stationName, String[] sensorNames, int minTimestamp, int maxTimestamp) {
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		if(stationMeta==null){
			throw new RuntimeException("no station: "+stationName);
		}
		
		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);
		ArrayList<StreamIterator> streamIteratorList = new ArrayList<StreamIterator>();
		for(String name:sensorNames) {
			SensorMeta sensorMeta = sensorMap.get(name);
			if(sensorMeta!=null) {
				BTreeMap<Integer, ArrayList<DataEntry>> sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);
				StreamIterator it = new StreamIterator(sensorMeta, sensorChunkMap, minTimestamp, maxTimestamp);
				if(it.hasNext()) {
					streamIteratorList.add(it);
				}
			}
		}
		return new RelationalIterator(streamIteratorList.toArray(new StreamIterator[0]),sensorNames);
	}
}
