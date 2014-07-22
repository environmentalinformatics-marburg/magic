package timeseriesdatabase.aggregated.iterator;

import java.util.List;

import de.umr.jepc.store.Event;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class ProjectionIterator extends TimeSeriesIterator {

	private TimeSeriesIterator input_iterator;
	private int[] eventPos;

	public ProjectionIterator(TimeSeriesIterator input_iterator, String[] outputSchema) {
		super(TimeSeriesSchema.createJustSchema(outputSchema));
		this.input_iterator = input_iterator;
		this.eventPos = Util.stringArrayToPositionIndexArray(outputSchema, input_iterator.getOutputSchema(), true, true);
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		TimeSeriesEntry element = input_iterator.next();
		float[] data = new float[outputTimeSeriesSchema.columns];
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			data[i] = element.data[eventPos[i]];
		}
		return new TimeSeriesEntry(element.timestamp,data);
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}

	@Override
	public String getIteratorName() {
		return "ProjectionIterator";
	}

}
