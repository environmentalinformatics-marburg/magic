package timeseriesdatabase.raw;

import java.util.Iterator;

import util.OutputSchema;
import util.SchemaIterator;
import util.Util;
import de.umr.jepc.store.Event;

public class EventConverterIterator implements SchemaIterator<TimestampSeriesEntry> {	
	private String[] inputSchema;
	private String[] outputSchema;
	private Iterator<Event> inputIterator;
	private int[] eventPos;

	public EventConverterIterator(String[] inputSchema, Iterator<Event> inputIterator, String[] outputSchema) {
		this.inputSchema = inputSchema;
		this.outputSchema = outputSchema;
		this.inputIterator = inputIterator;
		eventPos = Util.stringArrayToPositionIndexArray(outputSchema, inputSchema, true);
	}

	@Override
	public boolean hasNext() {
		return inputIterator.hasNext();
	}

	@Override
	public TimestampSeriesEntry next() {
		Event event = inputIterator.next();
		Object[] payload = event.getPayload();
		float[] data = new float[payload.length];
		for(int i=0;i<inputSchema.length;i++) {
			data[i] = (float) payload[eventPos[i]];
		}
		return new TimestampSeriesEntry(event.getTimestamp(),data);
	}

	@Override
	public String[] getOutputSchema() {
		return outputSchema;
	}

}
