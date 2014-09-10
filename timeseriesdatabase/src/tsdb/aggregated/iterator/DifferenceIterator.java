package tsdb.aggregated.iterator;

import java.util.List;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.iterator.TimeSeriesIterator;

public class DifferenceIterator extends TimeSeriesIterator {
	private TimeSeriesIterator input_iterator;
	private TimeSeriesIterator compare_iterator;
	private final boolean absoluteDifference;

	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema, TimeSeriesSchema compare_schema) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;
		boolean hasQualityFlags = false; //maybe TODO
		boolean hasInterpolatedFlags = false; //maybe TODO
		boolean hasQualityCounters = false; //maybe TODO
		if(!TimeSeriesSchema.isSameSchemaNames(input_schema.schema, compare_schema.schema)) {
			throw new RuntimeException("needs same schema");
		}
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}

	public DifferenceIterator(TimeSeriesIterator input_iterator, TimeSeriesIterator compare_iterator, boolean absoluteDifference) {
		super(createSchema(input_iterator.getOutputTimeSeriesSchema(),compare_iterator.getOutputTimeSeriesSchema()));
		this.input_iterator = input_iterator;
		this.compare_iterator = compare_iterator;
		this.absoluteDifference = absoluteDifference;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		TimeSeriesEntry element = input_iterator.next();
		TimeSeriesEntry genElement = compare_iterator.next();
		long timestamp = element.timestamp;
		if(timestamp!= genElement.timestamp) {
			throw new RuntimeException("iterator error");
		}

		float[] result = new float[outputTimeSeriesSchema.columns];
		for(int colIndex=0;colIndex<outputTimeSeriesSchema.columns;colIndex++) {
			if(absoluteDifference) {
				result[colIndex] = Math.abs(element.data[colIndex]-genElement.data[colIndex]);
			} else {
				result[colIndex] = element.data[colIndex]-genElement.data[colIndex];	
			}
		}
		return new TimeSeriesEntry(timestamp,result);
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}
}
