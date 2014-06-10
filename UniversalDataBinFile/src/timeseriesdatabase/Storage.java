package timeseriesdatabase; 

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Iterator;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.EventStore;
import de.umr.jepc.util.enums.CapacityUnit;


public class Storage {
	private static final Logger log = LogManager.getLogger("general");
	
	private static final Attribute[] FLOAT_ONE_SCHEMA = new Attribute[]{new Attribute("a",DataType.FLOAT)};
	
	private EventStore eventStore;
	private Method method_flushStream;
	
	public Storage() {	
		initEventStore();
	}
	
	public void close() {
		eventStore.close();
	}
	
	private void initEventStore(){
		try{
		Class<?> eventStoreClass = Class.forName("de.umr.jepc.store.btree.TimeSplitBTreeEventStore", true, this.getClass().getClassLoader());
		method_flushStream = eventStoreClass.getMethod("flushStream",String.class);
		eventStore = (EventStore) eventStoreClass.newInstance();
		eventStore.open();
		eventStore.setEventStoreCapacity(1024, CapacityUnit.GB);
		} catch (Exception e) {
			log.error("initEventStore:\t"+e);
		}
	}
	
	private void clear() {
		eventStore.clear();
	}
	
	private static String nameToID(String stationName, String sensorName) {
		if(sensorName.contains("/")) {
			sensorName = sensorName.replace('/', '_');
		}
		return stationName+"__"+sensorName;
	}

	public void createFloatStream(String streamID) {
		eventStore.registerStream(streamID, FLOAT_ONE_SCHEMA);		
	}
	
	public void writeTimeSeries(String streamID, long firstTimeStamp, float[] data) {
		Float[] event = new Float[1];

		for(int i=0;i<data.length;i++) {
			event[0] = data[i];
			eventStore.pushEvent(streamID, event, firstTimeStamp+(i*30));
		}

		try {
			method_flushStream.invoke(eventStore, streamID);
		} catch (IllegalAccessException | IllegalArgumentException
				| InvocationTargetException e1) {
			log.warn("in method_flushStream");
		}	
		
	}
	
	public void writeTimeSeries(String streamID, long[] time, float[] data) {
		Float[] payload = new Float[1];

		for(int i=0;i<data.length;i++) {
			payload[0] = data[i];
			eventStore.pushEvent(streamID, payload, time[i]);
		}

		try {
			method_flushStream.invoke(eventStore, streamID);
		} catch (IllegalAccessException | IllegalArgumentException
				| InvocationTargetException e1) {
			log.warn("in method_flushStream");
		}	
	}
	
	public Set<String> getStreamIDs() {
		return eventStore.getRegisteredStreams();
	}
	
	public Iterator<Event> queryTimeSeries(String streamID) {
		return eventStore.getHistory(streamID);
	}
	
	public Iterator<Event> queryTimeSeries(String streamID, long startTime, long endTime) {
		return eventStore.getHistoryRange(streamID, startTime, endTime);
	}
	
	public Iterator<Event> query(String sql) {
		return eventStore.query(sql);
	}

}
