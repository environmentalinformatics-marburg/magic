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

import static tsdb.util.AssumptionCheck.*;
import tsdb.util.iterator.TsIterator;


public class StreamDB {

	//private static final int CLUSTER_TIMESTAMP_SIZE = 262144;	

	private static final Logger log = LogManager.getLogger();

	private DB db;

	private static final String DB_NAME_STATION_MAP = "stationMap";

	private BTreeMap<String,StationMeta> stationMetaMap;

	public StreamDB(String streamdbPathPrefix) {
		String pathName = streamdbPathPrefix;

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


	private StationMeta getStationMeta(String stationName, boolean createIfNotExists) {
		throwNull(stationName);
		StationMeta stationMeta = stationMetaMap.get(stationName);		
		BTreeMap<String, SensorMeta> sensorMap;
		if(stationMeta==null&&createIfNotExists){
			stationMeta = new StationMeta(stationName);
			db.checkNameNotExists(stationMeta.db_name_sensor_map);
			db.createTreeMap(stationMeta.db_name_sensor_map)
			.keySerializer(BTreeKeySerializer.STRING)
			.valueSerializer(SensorMeta.SERIALIZER)
			.makeOrGet();
			stationMetaMap.put(stationName, stationMeta);			
		}
		if(stationMeta==null) {
			log.warn("no station: "+stationName);
		}
		return stationMeta;
	}

	private SensorMeta getSensorMeta(StationMeta stationMeta, String sensorName, boolean createIfNotExists) {
		throwNull(stationMeta);
		throwNull(sensorName);
		BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);
		SensorMeta sensorMeta = sensorMap.get(sensorName);
		if(sensorMeta==null&&createIfNotExists) {
			sensorMeta = new SensorMeta(stationMeta.stationName, sensorName);
			db.checkNameNotExists(sensorMeta.db_name_sensor_chunk_map);
			db.createTreeMap(sensorMeta.db_name_sensor_chunk_map)
			.keySerializer(BTreeKeySerializer.ZERO_OR_POSITIVE_INT)
			.valueSerializer(DataEntry.CHUNK_SERIALIZER_DELTA_TIME_DELTA_INT_VALUE)
			.valuesOutsideNodesEnable()
			.makeOrGet();
			db.checkNameNotExists(sensorMeta.db_name_sensor_chunkmeta_map);
			db.createTreeMap(sensorMeta.db_name_sensor_chunkmeta_map)
			.keySerializer(BTreeKeySerializer.ZERO_OR_POSITIVE_INT)
			.valueSerializer(ChunkMeta.SERIALIZER)
			.makeOrGet();
			sensorMap.put(sensorName, sensorMeta);
		}
		if(sensorMeta==null) {
			log.warn("no sensor: "+sensorName+"  in station: "+stationMeta.stationName);
		}
		return sensorMeta;
	}

	private SensorMeta getSensorMeta(String stationName, String sensorName, boolean createIfNotExists) {
		throwNull(stationName);
		throwNull(sensorName);
		if(createIfNotExists) {
			return getSensorMeta(getStationMeta(stationName, true), sensorName,true);
		} else {
			StationMeta stationMeta = getStationMeta(stationName, false);
			if(stationMeta==null) {
				return null;
			}
			return getSensorMeta(stationMeta, sensorName, false);
		}
	}


	private BTreeMap<Integer, DataEntry[]> getSensorChunkMap(SensorMeta sensorMeta) {
		throwNull(sensorMeta);
		return db.getTreeMap(sensorMeta.db_name_sensor_chunk_map);
	}
	
	private BTreeMap<Integer, ChunkMeta> getSensorChunkMetaMap(SensorMeta sensorMeta) {
		throwNull(sensorMeta);
		return db.getTreeMap(sensorMeta.db_name_sensor_chunkmeta_map);
	}


	public void insertData(String stationName, String sensorName, DataEntry[] data) {
		
		SensorMeta sensorMeta = getSensorMeta(stationName,sensorName,true);
		BTreeMap<Integer, DataEntry[]> chunkMap = getSensorChunkMap(sensorMeta);
		BTreeMap<Integer, ChunkMeta> chunkMetaMap = getSensorChunkMetaMap(sensorMeta);
		
		chunkMap.put(data[0].timestamp, data);
		chunkMetaMap.put(data[0].timestamp, new ChunkMeta(data[0].timestamp,data[data.length-1].timestamp));

		/*
		BTreeMap<String, SensorMeta> sensorMap = getSensorMap(stationName);

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
		sensorMap.put(sensorName, sensorMeta);*/
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
		SensorMeta sensorMeta = getSensorMeta(stationName,sensorName,false);
		if(sensorMeta==null) {
			return null;
		}
		return getSensorIterator(sensorMeta,minTimestamp,maxTimestamp);
	}
	
	public StreamIterator getSensorIterator(StationMeta stationMeta, String sensorName, int minTimestamp, int maxTimestamp) {
		throwNull(stationMeta);
		SensorMeta sensorMeta = getSensorMeta(stationMeta,sensorName,false);
		if(sensorMeta==null) {
			return null;
		}
		return getSensorIterator(sensorMeta,minTimestamp,maxTimestamp);
	}
	
	public StreamIterator getSensorIterator(SensorMeta sensorMeta, int minTimestamp, int maxTimestamp) {
		throwNull(sensorMeta);
		BTreeMap<Integer, DataEntry[]> chunkMap = getSensorChunkMap(sensorMeta);
		BTreeMap<Integer, ChunkMeta> chunkMetaMap = getSensorChunkMetaMap(sensorMeta);
		return new StreamIterator(sensorMeta, chunkMetaMap, chunkMap, minTimestamp, maxTimestamp);	
	}
			
	
	public StreamTsIterator getSensorTsIterator(String stationName, String sensorName, int minTimestamp, int maxTimestamp) {
		StreamIterator it = getSensorIterator(stationName, sensorName, minTimestamp, maxTimestamp);
		if(it==null) {
			return null;
		}
		return new StreamTsIterator(it);
	}

	public TsIterator getTsIterator(String stationName, String[] sensorNames, int minTimestamp, int maxTimestamp) {
		if(sensorNames==null||sensorNames.length<1) {
			log.error("no sensors");
			return null;
		}
		if(sensorNames.length==1) {
			return getSensorTsIterator(stationName, sensorNames[0], minTimestamp, maxTimestamp);
		}
		StationMeta stationMeta = getStationMeta(stationName, false);
		if(stationMeta==null) {
			return null;
		}
		ArrayList<StreamIterator> streamIteratorList = new ArrayList<StreamIterator>();
		for(String sensorName:sensorNames) {			
			StreamIterator it = getSensorIterator(stationMeta, sensorName, minTimestamp, maxTimestamp);
			if(it!=null&&it.hasNext()) {
				streamIteratorList.add(it);
			}
		}
		return new RelationalIterator(streamIteratorList.toArray(new StreamIterator[0]),sensorNames);

		/*BTreeMap<String, SensorMeta> sensorMap = db.getTreeMap(stationMeta.db_name_sensor_map);
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
		}*/
	}
	
	public BTreeMap<String, SensorMeta> getSensorMap(StationMeta stationMeta) {
		throwNull(stationMeta);
		return db.getTreeMap(stationMeta.db_name_sensor_map);
	}
	
	public BTreeMap<String, SensorMeta> getSensorMap(String stationName) {
		throwNull(stationName);
		StationMeta stationMeta = getStationMeta(stationName, false);
		if(stationMeta==null){
			return null;
		}		
		return getSensorMap(stationMeta);
	}
	
	public int[] getSensorInterval(SensorMeta sensorMeta) {
		throwNull(sensorMeta);
		BTreeMap<Integer, ChunkMeta> chunkMetaMap = getSensorChunkMetaMap(sensorMeta);
		if(chunkMetaMap.isEmpty()) {
			return null;
		}
		return new int[]{chunkMetaMap.firstKey(),chunkMetaMap.lastEntry().getValue().lastTimestamp};
	}

	public int[] getTimeInterval(String stationName) {		
		BTreeMap<String, SensorMeta> sensorMap = getSensorMap(stationName);
		if(sensorMap==null||sensorMap.isEmpty()) {
			return null;
		}
		int minTimestamp = Integer.MAX_VALUE;
		int maxTimestamp = Integer.MIN_VALUE;
		for(SensorMeta sensorMeta:sensorMap.values()) {
			int[] interval = getSensorInterval(sensorMeta);
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
