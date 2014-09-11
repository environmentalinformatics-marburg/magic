package tsdb.aggregated.iterator;

import java.util.List;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsSchema;
import tsdb.util.TsSchema.Aggregation;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class DifferenceIterator extends TsIterator {
	private TsIterator input_iterator;
	private TsIterator compare_iterator;
	private final boolean absoluteDifference;

	public static TsSchema createSchema(TsSchema input_schema, TsSchema compare_schema) {
		TsSchema.throwDifferentNames(input_schema, compare_schema);
		TsSchema.throwDifferentAggregation(input_schema, compare_schema);
		TsSchema.throwDifferentTimeStep(input_schema, compare_schema);
		input_schema.throwNotContinuous();
		compare_schema.throwNotContinuous();
		boolean isContinuous = true;
		return new TsSchema(input_schema.names, input_schema.aggregation, input_schema.timeStep, isContinuous);
	}

	public DifferenceIterator(TsIterator input_iterator, TsIterator compare_iterator, boolean absoluteDifference) {
		super(createSchema(input_iterator.getSchema(),compare_iterator.getSchema()));
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

		float[] result = new float[schema.length];
		for(int colIndex=0;colIndex<schema.length;colIndex++) {
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
