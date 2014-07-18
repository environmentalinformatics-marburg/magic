package timeseriesdatabase;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.TreeMap;

import org.apache.logging.log4j.Logger;

import util.Util;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.btree.TimeSplitBTreeEventStore;
import de.umr.jepc.util.enums.TimeRepresentation;

/**
 * This class encapsulates EventStore and provides basic methods store and query time series data. 
 * @author woellauer
 *
 */
public class StreamStorage {

	private static final Logger log = Util.log;

	private TimeSplitBTreeEventStore store;

	public StreamStorage(String databasePath, String evenstoreConfigFile) {
		FileInputStream configStream = null; 
		try {
			configStream = new FileInputStream(evenstoreConfigFile);
		} catch (FileNotFoundException e) {
			log.error(configStream);
		}
		store = new TimeSplitBTreeEventStore(TimeRepresentation.POINT,databasePath,configStream);
		store.open();
	}

	public void registerStream(String streamName, Attribute[] attributes) {
		store.registerStream(streamName, attributes);

	}

	/**
	 * deletes all time series.
	 */
	public void clear() {
		store.clear();		
	}

	/**
	 * closes all open files and flushes pending data to disk.
	 */
	public void close() {
		store.close();		
	}

	/**
	 * Saves new data on disk. If some timestamps exist already in database, no data is overwritten.
	 * @param streamName
	 * @param eventMap
	 */
	public void insertData(String streamName, TreeMap<Long,Event> eventMap) {

		long startTimestamp = eventMap.firstKey();
		long endTimestamp = eventMap.lastKey();

		Map<Long,Event> storageMap = new HashMap<Long,Event>();
		Iterator<Event> it = queryRawEvents(streamName, startTimestamp, endTimestamp);
		if(it!=null) {
			while(it.hasNext()) {
				Event e = it.next();
				if(storageMap.containsKey(e.getTimestamp())) {
					log.error("duplicate timestamp events in database");
				} else {
					storageMap.put(e.getTimestamp(), e);
				}
			}
		}

		for(Event event:eventMap.values()) {
			if(storageMap.containsKey(event.getTimestamp())) {
				// event already in database	
			} else {
				store.pushEvent(streamName, event.getPayload(),event.getTimestamp());
			}
		}
		store.flushStream(streamName);
	}

	/**
	 * Basic method for all queries
	 * @param streamName
	 * @param start may be null
	 * @param end may be null
	 * @return iterator of events
	 */
	public Iterator<Event> queryRawEvents(String streamName, Long start, Long end) {
		if(start!=null) {
			long startTime = start;
			if(end!=null) {
				long endTime = end;
				return store.getHistoryRange(streamName, startTime, endTime);
			} else {
				return store.getFreshestHistory(streamName, startTime);
			}
		} else {
			if(end!=null) {
				long endTime = end;
				return store.getHistoryRange(streamName, Long.MIN_VALUE, endTime);
			} else {
				return store.getHistory(streamName);
			}
		}
	}

}