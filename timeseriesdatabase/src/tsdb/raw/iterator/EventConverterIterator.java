package tsdb.raw.iterator;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.ProcessingChainTitle;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;
import de.umr.jepc.store.Event;

/**
 * Converts input events from EventStrore to TimeSeriesEntries 
 * @author woellauer
 *
 */
public class EventConverterIterator extends TsIterator {	
	private Iterator<Event> inputIterator;
	private int[] eventPos;

	public EventConverterIterator(String[] inputSchema, Iterator<Event> inputIterator, String[] outputSchema) {
		super(new TsSchema(outputSchema));
		this.inputIterator = inputIterator;		
		eventPos = Util.stringArrayToPositionIndexArray(outputSchema, inputSchema, true, true);
	}

	@Override
	public boolean hasNext() {
		return inputIterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		Event event = inputIterator.next();
		//System.out.println("event: "+event);
		Object[] payload = event.getPayload();
		float[] data = new float[schema.length];
		for(int i=0;i<schema.length;i++) {
			data[i] = (float) payload[eventPos[i]];
		}
		return new TimeSeriesEntry(event.getTimestamp(),data);
	}
}
