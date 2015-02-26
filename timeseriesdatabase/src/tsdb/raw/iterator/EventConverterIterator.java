package tsdb.raw.iterator;

import java.util.Iterator;

import tsdb.DataRow;
import tsdb.raw.TsEntry;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

/**
 * Converts input events from EventStrore to TimeSeriesEntries 
 * @author woellauer
 *
 */
public class EventConverterIterator extends TsIterator {	
	private Iterator<DataRow> inputIterator;
	private int[] eventPos;

	public EventConverterIterator(String[] inputSchema, Iterator<DataRow> inputIterator, String[] outputSchema) {
		super(new TsSchema(outputSchema));
		this.inputIterator = inputIterator;		
		eventPos = Util.stringArrayToPositionIndexArray(outputSchema, inputSchema, true, true);
	}

	@Override
	public boolean hasNext() {
		return inputIterator.hasNext();
	}

	@Override
	public TsEntry next() {
		DataRow event = inputIterator.next();
		//System.out.println("event: "+event);
		Object[] payload = event.data;
		float[] data = new float[schema.length];
		for(int i=0;i<schema.length;i++) {
			data[i] = (float) payload[eventPos[i]];
		}
		return new TsEntry(event.timestamp,data);
	}
}
