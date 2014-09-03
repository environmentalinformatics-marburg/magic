package tsdb.aggregated.iterator;

import java.util.List;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.Util;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.MoveIterator;
import tsdb.util.iterator.TimeSeriesIterator;

public class DifferentialIterator extends InputProcessingIterator {
	
	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = false;
		int timeStep = TimeSeriesSchema.NO_CONSTANT_TIMESTEP;
		input_schema.throwNotContinuous();
		boolean isContinuous = input_schema.isContinuous;		
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false;
		boolean hasQualityCounters = false;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters);		
	}
	
	private final int columns;
	
	private float[]  prev = null;
	
	public DifferentialIterator(TimeSeriesIterator input_iterator) {
		super(input_iterator, createSchema(input_iterator.getOutputTimeSeriesSchema()));
		columns = this.outputTimeSeriesSchema.columns;
		prev = new float[columns];
		for(int col=0;col<columns;col++) {
			prev[col] = Float.NaN;
		}
	}	

	@Override
	protected TimeSeriesEntry getNext() {
		if(!input_iterator.hasNext()) {
			return null;
		}
		TimeSeriesEntry element = input_iterator.next();
		float[] curr = element.data;
		float[] data = new float[columns];
		for(int col=0;col<columns;col++) {
			if(!Float.isNaN(prev[col])&&!Float.isNaN(curr[col])) {
				data[col] = curr[col]-prev[col];
			} else {
				data[col] = Float.NaN;
			}
			prev[col] = curr[col];
		}
		return new TimeSeriesEntry(element.timestamp, data);
	}
}
