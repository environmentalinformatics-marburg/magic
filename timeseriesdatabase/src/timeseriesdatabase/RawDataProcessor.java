package timeseriesdatabase;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.Logger;

import util.Util;
import de.umr.jepc.store.Event;

/**
 * collects raw sensor data and returns a TimeSeries Object
 * 
 * Implemented processing:
 * - return only data with time stamp within query time interval 
 * - check and mapping from station type to query sensor names
 * - remove empty rows (rows that consist of NaN values only)
 * - remove empty columns
 * 
 * @author Stephan Wöllauer
 *
 */
public class RawDataProcessor {
	
	private static final Logger log = Util.log;
	
	String[] parameterNames;
	int[] eventPos;// mapping of input event columns to output data columns

	public RawDataProcessor(String[] schemaSensorNames, String[] querySensorNames) {
		parameterNames = getResultSchema(schemaSensorNames, querySensorNames);
		eventPos = Util.stringArrayToPositionIndexArray(parameterNames, schemaSensorNames, true);
	}

	public TimeSeries process(Iterator<Event> it) {	
		List<TimeSeriesEntry> entryList = new ArrayList<TimeSeriesEntry>();

		while(it.hasNext()) { // begin of while-loop for raw input-events
			Event event = it.next();
			long timestamp = event.getTimestamp();
			Object[] payload = event.getPayload();

			float[] data = new float[parameterNames.length];
			int validColumnCounter=0;
			for(int i=0;i<parameterNames.length;i++) {
				float value = (float) payload[eventPos[i]];
				if(Float.isNaN(value)) {
					data[i] = Float.NaN;
				} else {
					data[i] = value;
					validColumnCounter++;
				}

			}
			if(validColumnCounter>0) {
				entryList.add(new TimeSeriesEntry(timestamp,data));
			}
		}

		TimeSeries timeSeries = new TimeSeries(parameterNames, entryList, null);
		timeSeries.removeEmptyColumns();		
		return timeSeries;
	}
	
	private static String[] getResultSchema(String[] schemaSensorNames, String[] querySensorNames) {
		if(querySensorNames==null) {// all available sensors are in result schema
			return schemaSensorNames;			
		} else {		
			Map<String, Integer> schemaSensorNameMap = Util.StringArrayToMap(schemaSensorNames);
			ArrayList<String> parameterNameList = new ArrayList<String>();		
			for(String querySensorName:querySensorNames) {
				if(schemaSensorNameMap.containsKey(querySensorName)) {
						parameterNameList.add(querySensorName);
				} else {
					log.warn(querySensorName+" not in schema: "+schemaSensorNameMap);
				}
			}
			return (String[]) parameterNameList.toArray(new String[0]);
		}
	}
}
