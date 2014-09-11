package tsdb.aggregated.iterator;

import tsdb.util.TimeSeriesSchema;

public class DayAggregationIterator extends AbstractAggregationIterator {//needs input as hour values
	
	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema) { 
		String[] schema = input_schema.schema;
		if(!input_schema.constantTimeStep) {
			throw new RuntimeException("no constant time step");
		}
		if(!input_schema.isContinuous) {
			throw new RuntimeException("not continuous");
		}
		if(input_schema.hasQualityCounters) {
			throw new RuntimeException("quality counters are not usable as input");
		}
		boolean constantTimeStep = false;
		int timeStep = TimeSeriesSchema.NO_CONSTANT_TIMESTEP;
		boolean isContinuous = false; //??		
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false; //??
		boolean hasQualityCounters = input_schema.hasQualityFlags;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters);
		
	}

}
