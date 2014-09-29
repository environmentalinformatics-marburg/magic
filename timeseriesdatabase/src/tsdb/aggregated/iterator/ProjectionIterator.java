package tsdb.aggregated.iterator;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TsSchema;
import tsdb.util.TsSchema.Aggregation;
import tsdb.util.Util;
import tsdb.util.iterator.InputIterator;
import tsdb.util.iterator.TsIterator;

public class ProjectionIterator extends InputIterator {

	private int[] eventPos;
	
	public static TsSchema createSchema(TsSchema tsSchema, String[] outputSchema) {
		String[] names = outputSchema;
		Aggregation aggregation = tsSchema.aggregation;
		int timeStep = tsSchema.timeStep;
		boolean isContinuous = tsSchema.isContinuous;
		boolean hasQualityFlags = tsSchema.hasQualityFlags;
		boolean hasInterpolatedFlags = tsSchema.hasInterpolatedFlags;
		boolean hasQualityCounters = tsSchema.hasQualityCounters;
		return new TsSchema(names, aggregation, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters); 
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
