package tsdb.aggregated.iterator;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.TimeSeriesIterator;

public class LinearIterpolationIterator extends InputProcessingIterator {
	
	TimeSeriesEntry prev = null;
	TimeSeriesEntry curr = null;
	TimeSeriesEntry next = null;
	
	private int interpolationCount = 0;
	
	private static TimeSeriesSchema createSchema(TimeSeriesIterator input_iterator) {
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

	public LinearIterpolationIterator(TimeSeriesIterator input_iterator) {
		super(input_iterator, createSchema(input_iterator));
		if(input_iterator.hasNext()) {
			next = input_iterator.next();
		}
	}

	@Override
	protected TimeSeriesEntry getNext() {
		if(next==null) {// no elements left
			return null;
		}
		prev = curr;
		curr = next;
		if(input_iterator.hasNext()) {
			next = input_iterator.next();
		} else { //no next element
			System.out.println("LinearIterpolationIterator interpolated: "+interpolationCount);
			next = null;
		}
		if(prev!=null&&next!=null) { // interpolation possible
			boolean interpolate=false;
			for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
				if(Float.isNaN(curr.data[i])&&(!Float.isNaN(prev.data[i]))&&(!Float.isNaN(next.data[i]))) {
					interpolate = true;
					break;
				}
			}
			if(!interpolate) {
				return curr;
			}
			float[] result = new float[outputTimeSeriesSchema.columns];
			for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
				if(Float.isNaN(curr.data[i])&&(!Float.isNaN(prev.data[i]))&&(!Float.isNaN(next.data[i]))) {
					result[i] = (prev.data[i]+next.data[i])/2;
					interpolationCount++;
				} else {
					result[i] = curr.data[i];
				}
			}
			TimeSeriesEntry res = new TimeSeriesEntry(curr.timestamp, result);
			System.out.println("-"+curr);
			System.out.println("+"+res);			
			return res;
		} else { // curr is first or last in iterator
			return curr;
		}
	}

}
