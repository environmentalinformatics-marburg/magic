package tsdb.aggregated.iterator;

import tsdb.DataQuality;
import tsdb.raw.TsEntry;
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
	public TsEntry next() {
		TsEntry element = input_iterator.next();
		float[] data = new float[schema.length];
		if(element.interpolated!=null)
		for(int i=0;i<schema.length;i++) {
			data[i] = element.data[eventPos[i]];
		}
		DataQuality[] qualityFlag = null;
		if(element.qualityFlag!=null) {
			qualityFlag = new DataQuality[schema.length];
			for(int i=0;i<schema.length;i++) {
				qualityFlag[i] = element.qualityFlag[eventPos[i]];
			}
		}
		boolean[] interpolated = null;
		if(element.interpolated!=null) {
			interpolated = new boolean[schema.length];
			for(int i=0;i<schema.length;i++) {
				interpolated[i] = element.interpolated[eventPos[i]];
			}
		}
		int[][] qualityCounter = null; //TODO		
		return new TsEntry(element.timestamp, data, qualityFlag, qualityCounter, interpolated);
		//return new TsEntry(element.timestamp,data);
	}
}
