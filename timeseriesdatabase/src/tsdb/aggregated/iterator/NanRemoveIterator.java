package tsdb.aggregated.iterator;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsSchema;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.TsIterator;

/**
 * Sends only input elements to output that have at least one not NaN-value in data.
 * @author woellauer
 *
 */
public class NanRemoveIterator extends InputProcessingIterator {
	
	public static TsSchema createSchema(TsSchema tsschema) {
		TimeSeriesSchema input_schema = tsschema.toTimeSeriesSchema();
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = false;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep , isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters).toTsSchema();		
	}

	public NanRemoveIterator(TsIterator input_iterator) {
		super(input_iterator, createSchema(input_iterator.getSchema()));
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
}
