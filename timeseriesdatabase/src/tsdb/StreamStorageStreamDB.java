package tsdb;

import java.util.Iterator;
import java.util.List;
import java.util.TreeMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.streamdb.StreamDB;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

public class StreamStorageStreamDB implements StreamStorage {
	
	private static final Logger log = LogManager.getLogger();
	
	private StreamDB streamdb;
	
	public StreamStorageStreamDB(String streamdbPathPrefix) {
		this.streamdb = new StreamDB(streamdbPathPrefix);
	}

	@Override
	public void registerStream(String streamName, Attribute[] attributes) {
		// TODO Auto-generated method stub		
	}

	@Override
	public void clear() {
		// TODO Auto-generated method stub		
	}

	@Override
	public void close() {
		streamdb.close();		
	}

	@Override
	public void insertData(String streamName, TreeMap<Long, Event> eventMap, String[] sensorNames) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void insertEventList(String streamName, List<Event> eventList,long first, long last) {
		// TODO Auto-generated method stub		
	}

	@Override
	public Iterator<Event> queryRawEvents(String streamName, Long start, Long end) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public TsIterator getRawIterator(String stationName, String[] sensorNames, Long start, Long end, String[] eventSchema) {
		log.info("StreamDB get "+stationName+" with "+Util.arrayToString(sensorNames));
		int minTimestamp;
		int maxTimestamp;
		if(start==null) {
			minTimestamp = Integer.MIN_VALUE;
		} else {
			minTimestamp = (int)(long)start;
		}
		if(end==null) {
			maxTimestamp = Integer.MAX_VALUE;
		} else {
			maxTimestamp = (int)(long)end;
		}		
		return streamdb.getTsIterator(stationName, sensorNames, minTimestamp, maxTimestamp);
	}

	@Override
	public void getInfo() {
		// TODO Auto-generated method stub		
	}

	@Override
	public long[] getTimeInterval(String streamName) {
		int[] interval = streamdb.getTimeInterval(streamName);
		if(interval==null) {
			return null;
		}
		return new long[]{interval[0],interval[1]};
	}

}
