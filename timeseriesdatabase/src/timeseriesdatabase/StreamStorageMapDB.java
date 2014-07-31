package timeseriesdatabase;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.File;
import java.io.IOException;
import java.io.Serializable;
import java.util.Iterator;
import java.util.Map.Entry;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentNavigableMap;

import org.apache.logging.log4j.Logger;
import org.mapdb.BTreeMap;
import org.mapdb.DB;
import org.mapdb.DBMaker;
import org.mapdb.Serializer;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.TimeSeriesSchema;
import util.Util;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

public class StreamStorageMapDB implements StreamStorage {
	
	private static final Logger log = Util.log;
	
	private static class StorageEntry implements Serializable {
		private static final long serialVersionUID = 2832034902535063248L;
		public final long timestamp;
		public final float[] data;
		public StorageEntry(long timestamp, float[] data) {
			this.timestamp = timestamp;
			this.data = data;
		}
	}
	
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
		@Override
		public void serialize(DataOutput out, Event event)
				throws IOException {
			out.writeLong(event.getTimestamp());
			Object[] payload = event.getPayload();
			out.write(payload.length);
			for(Object value:payload) {
				out.writeFloat((Float)value);
			}
		}

		@Override
		public Event deserialize(DataInput in, int available)
				throws IOException {
			long timestamp = in.readLong();
			int size = in.readInt();
			Object[] payload = new Object[size];
			for(int i=0;i<size;i++) {
				payload[i] = in.readFloat();
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
		db.close();		
	}

	@Override
	public void insertData(String streamName, TreeMap<Long, Event> eventMap) {
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
	
	private ConcurrentNavigableMap<Long, StorageEntry> queryMap(String streamName, Long begin, Long end) {
		String dbName = DB_NAME_STREAM_PREFIX+streamName;
		if(streamMetadataMap.containsKey(dbName)) {
			ConcurrentNavigableMap<Long, StorageEntry> map = db.getTreeMap(dbName);
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
		ConcurrentNavigableMap<Long, StorageEntry> map = queryMap(streamName, start, end);
		if(map==null) {
			return null;
		}
		Iterator<StorageEntry> it = map.values().iterator();
		return new Iterator<Event>() {
			@Override
			public boolean hasNext() {
				return it.hasNext();
			}
			@Override
			public Event next() {
				StorageEntry element = it.next();
				float[] data = element.data;
				Object[] payload = new Object[data.length];
				for(int i=0;i<data.length;i++) {
					payload[i] = data[i];
				}
				return new Event(payload, element.timestamp);
			}};
	}

	@Override
	public void getInfo() {
		// TODO Auto-generated method stub
		
	}

}
