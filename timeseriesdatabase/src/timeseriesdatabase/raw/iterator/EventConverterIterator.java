package timeseriesdatabase.raw.iterator;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.OutputSchema;
import util.ProcessingChainEntry;
import util.ProcessingChainTitle;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;
import de.umr.jepc.store.Event;

/**
 * Converts input events from EventStrore to TimeSeriesEntries 
 * @author woellauer
 *
 */
public class EventConverterIterator extends TimeSeriesIterator {	
	private Iterator<Event> inputIterator;
	private int[] eventPos;

	public EventConverterIterator(String[] inputSchema, Iterator<Event> inputIterator, String[] outputSchema) {
		super(TimeSeriesSchema.createJustSchema(outputSchema));
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
		Object[] payload = event.getPayload();
		float[] data = new float[outputTimeSeriesSchema.columns];
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			data[i] = (float) payload[eventPos[i]];
		}
		return new TimeSeriesEntry(event.getTimestamp(),data);
	}

	@Override
	public String getIteratorName() {
		return "EventConverterIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = new ArrayList<ProcessingChainEntry>();
		result.add(new ProcessingChainTitle("Iterator<Event>"));
		result.add(this);
		return result;
	}
}
