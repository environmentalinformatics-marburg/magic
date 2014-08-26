package tsdb.aggregated.iterator;

import java.util.List;
import java.util.function.Function;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.iterator.TimeSeriesIterator;

public class ApplyIterator extends TimeSeriesIterator {
	
	private final TimeSeriesIterator input_iterator;
	private final Function<TimeSeriesEntry,TimeSeriesEntry> function;
	
	/*public static ApplyIterator createApply(TimeSeriesIterator input_iterator, Function<TimeSeriesEntry,TimeSeriesEntry> function) {
		return new ApplyIterator(input_iterator, function);
	}
	
	public static ApplyIterator createApplyAll(TimeSeriesIterator input_iterator, Function<Float,Float> function) {		
		Function<TimeSeriesEntry,TimeSeriesEntry> func = new Function<TimeSeriesEntry, TimeSeriesEntry>() {			
			@Override
			public TimeSeriesEntry apply(TimeSeriesEntry t) {				
				return null;
			}
		};
		
	}*/
	
	public static TimeSeriesSchema createSchema(TimeSeriesIterator input_iterator) {
		TimeSeriesSchema input_schema = input_iterator.getOutputTimeSeriesSchema();
		
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}

	public ApplyIterator(TimeSeriesIterator input_iterator, Function<TimeSeriesEntry,TimeSeriesEntry> function) {
		super(createSchema(input_iterator));
		this.input_iterator = input_iterator;
		this.function = function;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		return function.apply(input_iterator.next());
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}

	@Override
	public String getIteratorName() {
		return "ApplyIterator";
	}
	
	

}
