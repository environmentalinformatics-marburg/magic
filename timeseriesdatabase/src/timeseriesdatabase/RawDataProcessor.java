package timeseriesdatabase;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import de.umr.jepc.store.Event;

public class RawDataProcessor {

	String[] schemaSensorNames;

	public RawDataProcessor(String[] schemaSensorNames) {
		this.schemaSensorNames = schemaSensorNames;		
	}

	public TimeSeries process(Iterator<Event> it) {	
		List<TimeSeriesEntry> entryList = new ArrayList<TimeSeriesEntry>();

		while(it.hasNext()) { // begin of while-loop for raw input-events
			Event event = it.next();
			long timestamp = event.getTimestamp();
			Object[] payload = event.getPayload();

			float[] data = new float[schemaSensorNames.length];
			int validColumnCounter=0;
			for(int i=0;i<schemaSensorNames.length;i++) {
				float value = (float) payload[i];
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

		TimeSeries timeSeries = new TimeSeries(schemaSensorNames, entryList);
		timeSeries.removeEmptyColumns();		
		return new TimeSeries(schemaSensorNames, entryList);
	}

}
