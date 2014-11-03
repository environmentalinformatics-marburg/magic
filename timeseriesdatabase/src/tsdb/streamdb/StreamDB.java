package tsdb.streamdb;
import java.io.File;
import java.util.ArrayList;
import java.util.NavigableSet;
import java.util.Optional;
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
		String pathName = "c:/timeseriesdatabase_storage/db";
		//String pathName = "timeseriesdatabase_storage/db";
		db = DBMaker.newFileDB(new File(pathName))
				.compressionEnable()
				//.transactionDisable()
				//.mmapFileEnable() //slow commit and close!!!
				.mmapFileEnablePartial()
				.asyncWriteEnable()
				.asyncWriteFlushDelay(500)
				.cacheWeakRefEnable()
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

	public void insertData(String stationName, String sensorName, DataEntry[] data) {
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
		BTreeMap<Integer, DataEntry[]> sensorChunkMap;
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



		sensorChunkMap.put(data[0].timestamp, data);
		sensorMeta.list.add(new ChunkMetaEntry(data[0].timestamp,data[data.length-1].timestamp));
		sensorMap.put(sensorName, sensorMeta);
	}

	@Deprecated
	public DataEntry[] readData(String stationName, String sensorName) {
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		if(stationMeta==null){
			log.error("no station");
			return new DataEntry[0];
		}

		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);		
		SensorMeta sensorMeta = sensorMap.get(sensorName);
		if(sensorMeta==null) {
			log.error("no sensor");
			return new DataEntry[0];
		}

		BTreeMap<Integer, DataEntry[]> sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);


		for(DataEntry[] chunk:sensorChunkMap.values()) {
			return chunk;
		}
		return new DataEntry[0];
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

		BTreeMap<Integer, DataEntry[]> sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);

		return new StreamIterator(sensorMeta, sensorChunkMap, minTimestamp, maxTimestamp);	
	}

	public TsIterator getTsIterator(String stationName, String[] sensorNames, int minTimestamp, int maxTimestamp) {
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		if(stationMeta==null){
			log.warn("not in streamDB: "+stationName);
			return null;
		}
		if(sensorNames.length==0) {
			log.warn("no sensornames");
			return null;
		}

		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);
		ArrayList<StreamIterator> streamIteratorList = new ArrayList<StreamIterator>();

		if(sensorNames.length==1) {
			SensorMeta sensorMeta = sensorMap.get(sensorNames[0]);
			if(sensorMeta!=null) {
				BTreeMap<Integer, DataEntry[]> sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);
				StreamIterator it = new StreamIterator(sensorMeta, sensorChunkMap, minTimestamp, maxTimestamp);
				if(it.hasNext()) {
					return new StreamTsIterator(it);
				} else {
					return null;
				}
			} else {
				return null;
			}
		} else {
			for(String name:sensorNames) {
				SensorMeta sensorMeta = sensorMap.get(name);
				if(sensorMeta!=null) {
					BTreeMap<Integer, DataEntry[]> sensorChunkMap = db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);
					StreamIterator it = new StreamIterator(sensorMeta, sensorChunkMap, minTimestamp, maxTimestamp);
					if(it.hasNext()) {
						streamIteratorList.add(it);
					}
				}
			}
			return new RelationalIterator(streamIteratorList.toArray(new StreamIterator[0]),sensorNames);
		}
	}

	public int[] getTimeInterval(String stationName) {
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		if(stationMeta==null){
			log.warn("not in streamDB: "+stationName);
			return null;
		}

		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);
		if(sensorMap.isEmpty()) {
			return null;
		}
		int minTimestamp = Integer.MAX_VALUE;
		int maxTimestamp = Integer.MIN_VALUE;
		for(SensorMeta sensorMeta:sensorMap.values()) {
			int[] interval = sensorMeta.getInterval();
			if(interval!=null) {
				if(interval[0]<minTimestamp) {
					minTimestamp = interval[0];
				}
				if(maxTimestamp<interval[1]) {
					maxTimestamp = interval[1];
				}
			}
		}
		if(minTimestamp == Integer.MAX_VALUE || maxTimestamp == Integer.MIN_VALUE) {
			return null;
		}
		return new int[]{minTimestamp,maxTimestamp};	
	}
}
