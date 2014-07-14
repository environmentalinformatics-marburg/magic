package timeseriesdatabase.aggregated.iterator;

import java.util.List;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.iterator.MoveIterator;
import util.iterator.TimeSeriesIterator;

/**
 * Sends only input elements to output that have at least one not NaN-value in data.
 * @author woellauer
 *
 */
public class NanRemoveIterator extends MoveIterator{
	
	TimeSeriesIterator input_iterator;
	
	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = false;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep , isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
		
	}

	public NanRemoveIterator(TimeSeriesIterator input_iterator) {
		super(createSchema(input_iterator.getOutputTimeSeriesSchema()));
		this.input_iterator = input_iterator;
	}

	@Override
	protected TimeSeriesEntry getNext() {
		while(input_iterator.hasNext()) {
			TimeSeriesEntry next = input_iterator.next();
			int counter = 0;
			for(float v:next.data) {
				if(!Float.isNaN(v)) {
					counter++;
				}
			}
			if(counter>0) {
				return next;
			}
		}
		return null;
	}

	@Override
	public String getIteratorName() {
		return "NanGapIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}

}
