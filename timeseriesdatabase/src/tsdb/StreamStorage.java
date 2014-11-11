package tsdb;

import java.util.Iterator;
import java.util.List;
import java.util.TreeMap;

import tsdb.util.iterator.TsIterator;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

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
	 * @param sensorNames 
	 */
	public void insertData(String streamName, TreeMap<Long,Event> eventMap, String[] sensorNames);
	
	/**
	 * insert ordered list of data with time span first to last
	 * @param streamName
	 * @param eventList
	 * @param first
	 * @param last
	 */
	public void insertEventList(String streamName, List<Event> eventList, long first, long last);

	/**
	 * Basic method for all queries
	 * @param streamName
	 * @param start may be null
	 * @param end may be null
	 * @return iterator of events
	 */
	@Deprecated
	public Iterator<Event> queryRawEvents(String streamName, Long start, Long end);
	
	public TsIterator getRawIterator(String stationName, String[] sensorNames, Long minTimestamp, Long maxTimestamp, String[] eventSchema);
	
	public void getInfo();

	long[] getTimeInterval(String streamName);
}
