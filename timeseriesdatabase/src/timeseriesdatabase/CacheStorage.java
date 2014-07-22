package timeseriesdatabase;

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentNavigableMap;

import org.apache.logging.log4j.Logger;
import org.mapdb.BTreeMap;
import org.mapdb.DB;
import org.mapdb.DBMaker;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class CacheStorage {

	private static final Logger log = Util.log;

	private static final String DB_NAME_METADATA_SCHEMA = "schema";
	private static final String DB_NAME_STREAM_PREFIX = "stream_";

	/*
	 * Layout:
	 * stream_[name]
	 * metadata
	 * 
	 * 
	 * 
	 * 
	 */

	private DB db;
	private BTreeMap<String, TimeSeriesSchema> schemaMap;



	//private Map<String,ConcurrentNavigableMap<Long,TimeSeriesEntry>> streamMap;

	public CacheStorage(String cachePath) {
		this.db = DBMaker.newFileDB(new File(cachePath+"cachedb"))
				.closeOnJvmShutdown()
				.make();

		this.schemaMap = db.getTreeMap(DB_NAME_METADATA_SCHEMA);	
	}

	public void createNew(String streamName, TimeSeriesSchema timeSeriesSchema) {
		String dbName = DB_NAME_STREAM_PREFIX+streamName;
		db.delete(dbName);
		//ConcurrentNavigableMap<Long,TimeSeriesEntry> map = db.getTreeMap(streamName);
		//streamMap.put(streamName, map);
		schemaMap.remove(streamName);

		db.getTreeMap(dbName);
		schemaMap.put(streamName, timeSeriesSchema);

	}

	public ConcurrentNavigableMap<Long, TimeSeriesEntry> queryMap(String streamName, Long begin, Long end) {
		String dbName = DB_NAME_STREAM_PREFIX+streamName;
		if(schemaMap.containsKey(streamName)) {
			ConcurrentNavigableMap<Long, TimeSeriesEntry> map = db.getTreeMap(dbName);
			if(begin!=null) {
				Long fromKey = begin;
				if(end!=null) {
					Long toKey = end;
					return map.subMap(fromKey, true, toKey, true);
				} else {
					return map.tailMap(fromKey, true);
				}
			} else {
				if(end!=null) {
					Long toKey = end;
					return map.headMap(toKey, true);
				} else {
					return map;
				}
			}
		} else {
			log.error("stream not in database: "+streamName);
			return null;
		}
	}

	public  TimeSeriesIterator query(String streamName, Long begin, Long end) {		
		TimeSeriesSchema timeSeriesSchema = schemaMap.get(streamName);
		if(timeSeriesSchema!=null) {
			Iterator<TimeSeriesEntry> it = queryMap(streamName,begin,end).values().iterator();			
			TimeSeriesIterator it2 = new TimeSeriesIterator(timeSeriesSchema) {
				@Override
				public boolean hasNext() {
					return it.hasNext();
				}
				@Override
				public TimeSeriesEntry next() {
					return it.next();
				}
				@Override
				public List<ProcessingChainEntry> getProcessingChain() {
					List<ProcessingChainEntry> result = new ArrayList<ProcessingChainEntry>();
					result.add(this);
					return result;
				}
				@Override
				public String getIteratorName() {
					return "cache query iterator";
				}				
			};			
			return it2;
		} else {
			log.error("stream not in database: "+streamName);
			return null;
		}
	}

	public void writeNew(String streamName,TimeSeriesIterator input_iterator) {		
		createNew(streamName, input_iterator.getOutputTimeSeriesSchema());		
		String dbName = DB_NAME_STREAM_PREFIX+streamName;
		if(schemaMap.containsKey(streamName)) {
			ConcurrentNavigableMap<Long, TimeSeriesEntry> map = db.getTreeMap(dbName);
			while(input_iterator.hasNext()) {
				TimeSeriesEntry element = input_iterator.next();
				map.put(element.timestamp, element);
			}
		} else {
			log.error("stream not in database: "+streamName);
		}
		db.commit();
		/*ConcurrentNavigableMap<Long, TimeSeriesEntry> map = streamMap.get(streamName);
		if(map==null) {
			map = db.getTreeMap(streamName);
		}
		while(input_iterator.hasNext()) {
			TimeSeriesEntry element = input_iterator.next();
			map.put(element.timestamp, element);
		}
		db.commit();*/
	}

}
