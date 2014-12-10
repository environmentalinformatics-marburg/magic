package tsdb;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.File;
import java.io.IOException;
import java.io.Serializable;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentNavigableMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mapdb.BTreeMap;
import org.mapdb.DB;
import org.mapdb.DBMaker;
import org.mapdb.Serializer;

import tsdb.streamdb.StreamIterator;
import tsdb.util.iterator.TsIterator;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

public class StreamStorageMapDB implements StreamStorage{
	
	private static final Logger log = LogManager.getLogger();
	
	private static final String DB_NAME_STREAM_METADATA = "StreamMetadata";
	private static final String DB_NAME_STREAM_PREFIX = "stream_";
	
	private DB db;
	private BTreeMap<String, Attribute[]> streamMetadataMap;
	
	StreamStorageMapDB(String databasePath) {
		
		this.db = DBMaker.newFileDB(new File(databasePath+"database"))
				//.compressionEnable()
				.transactionDisable() //!!
				.mmapFileEnable() //!!
				.asyncWriteEnable() //!!
				.cacheSize(100000)  //!!
				.asyncWriteFlushDelay(100)
				.closeOnJvmShutdown()
				.make();
		
		if(db.getAll().containsKey(DB_NAME_STREAM_METADATA )) {
			this.streamMetadataMap = db.getTreeMap(DB_NAME_STREAM_METADATA );
		} else {
			this.streamMetadataMap =  db.createTreeMap(DB_NAME_STREAM_METADATA ).makeStringMap();
		}
		
	}
	
	private static final EventSerializer eventSerializer = new EventSerializer();
	
	private static class EventSerializer implements Serializer<Event>, Serializable {

		private static final long serialVersionUID = 4445560340458017667L;

		@Override
		public void serialize(DataOutput out, Event event)
				throws IOException {
			long timestamp = event.getTimestamp();
			Object[] payload = event.getPayload();
			int count = payload.length;
			out.writeLong(timestamp); // ** write long
			out.writeInt(count);      // ** write int
			for(int i=0;i<count;i++) {
				out.writeFloat((Float)payload[i]); // ** write float
			}
		}

		@Override
		public Event deserialize(DataInput in, int available)
				throws IOException {
			long timestamp = in.readLong(); // ** read long
			int count = in.readInt();        // ** read int
			Float[] payload = new Float[count];
			for(int i=0;i<count;i++) {
				payload[i] = in.readFloat(); // ** read float
			}
			return new Event(payload,timestamp);
		}

		@Override
		public int fixedSize() {
			return -1;
		}};

	@Override
	public void registerStream(String streamName, Attribute[] attributes) {
	    final String dbName = DB_NAME_STREAM_PREFIX+streamName;
		if(!streamMetadataMap.containsKey(dbName)) {

			db.createTreeMap(dbName).valueSerializer(eventSerializer).nodeSize(126).makeLongMap();
			streamMetadataMap.put(dbName, attributes);
		}
		
	}

	@Override
	public void clear() {
		for(String key:streamMetadataMap.keySet()) {
			db.delete(key);
		}
		streamMetadataMap.clear();
		db.commit();
		//db.compact();
	}

	@Override
	public void close() {
		db.commit();
		db.compact();
		db.close();		
	}

	@Override
	public void insertData(String streamName, TreeMap<Long, Event> eventMap, String[] sensorNames) {
		String dbName = DB_NAME_STREAM_PREFIX+streamName;
		
		Attribute[] attributes = streamMetadataMap.get(dbName);
		if(attributes!=null) {
		BTreeMap<Long, Event> map = db.getTreeMap(dbName);
		for(Entry<Long, Event> entry:eventMap.entrySet()) {
			long timestamp = entry.getKey();
			/*Object[] payload = entry.getValue().getPayload();
			float[] data = new float[payload.length];
			for(int i=0;i<payload.length;i++) {
				data[i] = (Float) payload[i];
			}*/
			//map.putIfAbsent(timestamp, new StorageEntry(timestamp,data));
			//map.put(timestamp, new StorageEntry(timestamp,data));
			map.put(timestamp,entry.getValue());
		}
		
		db.commit();
		
		} else {
			log.warn("stream not found: "+streamName);
		}
	}
	
	@Override
	public void insertEventList(String streamName, List<Event> eventList, long first, long last, String[] sensorNames) {
		String dbName = DB_NAME_STREAM_PREFIX+streamName;
		Attribute[] attributes = streamMetadataMap.get(dbName);
		if(attributes!=null) {
			BTreeMap<Long, Event> storeMap = db.getTreeMap(dbName);
			for(Event event:eventList) {
				storeMap.put(event.getTimestamp(), event);
			}
			db.commit();			
		} else {
			log.warn("stream not found: "+streamName);
		}
		
	}	
	
	private ConcurrentNavigableMap<Long, Event> queryMap(String streamName, Long begin, Long end) {
		String dbName = DB_NAME_STREAM_PREFIX+streamName;
		if(streamMetadataMap.containsKey(dbName)) {
			ConcurrentNavigableMap<Long, Event> map = db.getTreeMap(dbName);
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

	@Override
	public Iterator<Event> queryRawEvents(String streamName, Long start, Long end) {
		ConcurrentNavigableMap<Long, Event> map = queryMap(streamName, start, end);
		if(map==null) {
			return null;
		}
		return map.values().iterator();
	}

	@Override
	public void getInfo() {
		throw new RuntimeException("TODO");
		
	}

	@Override
	public long[] getTimeInterval(String streamName) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public TsIterator getRawIterator(String stationName, String[] sensorNames, Long minTimestamp, Long maxTimestamp,  String[] eventSchema) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public String[] getSensorNames(String stationName) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public StreamIterator getRawSensorIterator(String stationName,
			String sensorName, Long start, Long end) {
		// TODO Auto-generated method stub
		return null;
	}
}
