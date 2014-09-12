package tsdb.aggregated.iterator;

import java.util.List;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.InputIterator;
import tsdb.util.iterator.TsIterator;

public class ProjectionIterator extends InputIterator {

	private int[] eventPos;
	
	public static TsSchema createSchema(TsSchema tsschema, String[] outputSchema) {
		TimeSeriesSchema input_schema = tsschema.toTimeSeriesSchema();
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(outputSchema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters).toTsSchema();
	}

	public ProjectionIterator(TsIterator input_iterator, String[] outputSchema) {
		super(input_iterator, createSchema(input_iterator.getSchema(), outputSchema));
		this.eventPos = Util.stringArrayToPositionIndexArray(outputSchema, input_iterator.getNames(), true, true);
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		TimeSeriesEntry element = input_iterator.next();
		float[] data = new float[schema.length];
		for(int i=0;i<schema.length;i++) {
			data[i] = element.data[eventPos[i]];
		}
		return new TimeSeriesEntry(element.timestamp,data);
	}
}
