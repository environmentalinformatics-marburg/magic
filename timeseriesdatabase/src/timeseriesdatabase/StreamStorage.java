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
public interface StreamStorage {

	public void registerStream(String streamName, Attribute[] attributes);

	public void clear();

	/**
	 * closes all open files and flushes pending data to disk.
	 */
	public void close();

	/**
	 * Saves new data on disk. If some timestamps exist already in database, no data is overwritten.
	 * @param streamName
	 * @param eventMap
	 */
	public void insertData(String streamName, TreeMap<Long,Event> eventMap);

	/**
	 * Basic method for all queries
	 * @param streamName
	 * @param start may be null
	 * @param end may be null
	 * @return iterator of events
	 */
	public Iterator<Event> queryRawEvents(String streamName, Long start, Long end);
	
	public void getInfo();

}
