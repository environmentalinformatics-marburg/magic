package timeseriesdatabase.raw.iterator;

import java.util.Iterator;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.OutputSchema;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;
import de.umr.jepc.store.Event;

public class EventConverterIterator extends TimeSeriesIterator {	
	private String[] inputSchema;
	private Iterator<Event> inputIterator;
	private int[] eventPos;

	public EventConverterIterator(String[] inputSchema, Iterator<Event> inputIterator, String[] outputSchema) {
		super(new TimeSeriesSchema(outputSchema));
		this.inputSchema = inputSchema;
		this.inputIterator = inputIterator;
		eventPos = Util.stringArrayToPositionIndexArray(outputSchema, inputSchema, true);
	}

	@Override
	public boolean hasNext() {
		return inputIterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		Event event = inputIterator.next();
		Object[] payload = event.getPayload();
		float[] data = new float[outputTimeSeriesSchema.columns];
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			data[i] = (float) payload[eventPos[i]];
		}
		return new TimeSeriesEntry(event.getTimestamp(),data);
	}
}
