package tsdb.aggregated.iterator;

import java.util.List;

import de.umr.jepc.store.Event;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class ProjectionIterator extends TimeSeriesIterator {

	private TimeSeriesIterator input_iterator;
	private int[] eventPos;
	
	public static TimeSeriesSchema createSchema(TimeSeriesIterator input_iterator, String[] outputSchema) {
		TimeSeriesSchema input_schema = input_iterator.getOutputTimeSeriesSchema();
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(outputSchema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}

	public ProjectionIterator(TimeSeriesIterator input_iterator, String[] outputSchema) {
		super(createSchema(input_iterator, outputSchema));
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
