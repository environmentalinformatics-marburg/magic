package timeseriesdatabase.aggregated.iterator;

import java.util.List;
import java.util.Map;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.MoveIterator;
import util.iterator.TimeSeriesIterator;

/**
 * This iterator outputs elements of average values of input_iterator values.
 * input_iterators need to be in same timestamp per element order.
 * @author woellauer
 *
 */
public class AverageIterator extends MoveIterator {

	Map<String, Integer> schemaMap;
	private TimeSeriesIterator[] input_iterators;
	private final int minCount;

	private static TimeSeriesSchema createSchema(String[] schema, TimeSeriesIterator[] input_iterators) {
		boolean constantTimeStep = input_iterators[0].getOutputTimeSeriesSchema().constantTimeStep;
		int timeStep = input_iterators[0].getOutputTimeSeriesSchema().timeStep;
		boolean isContinuous = input_iterators[0].getOutputTimeSeriesSchema().isContinuous;		
		boolean hasQualityFlags = input_iterators[0].getOutputTimeSeriesSchema().hasQualityFlags;
		boolean hasInterpolatedFlags = input_iterators[0].getOutputTimeSeriesSchema().hasInterpolatedFlags;
		boolean hasQualityCounters = input_iterators[0].getOutputTimeSeriesSchema().hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}

	public AverageIterator(String[] schema, TimeSeriesIterator[] input_iterators, int minCount) {
		super(createSchema(schema, input_iterators));
		this.input_iterators = input_iterators;
		this.schemaMap = Util.stringArrayToMap(schema);
		this.minCount = minCount;
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterators[0].getProcessingChain();
		result.add(this);
		return result;
	}

	@Override
	protected TimeSeriesEntry getNext() {
		long timestamp = -1;
		int[] value_cnt = new int[this.outputTimeSeriesSchema.columns];
		float[] value_sum = new float[this.outputTimeSeriesSchema.columns];				
		for(TimeSeriesIterator it:input_iterators) {
			if(!it.hasNext()) {
				return null;
			}
			TimeSeriesEntry element = it.next();
			if(timestamp==-1) {
				timestamp = element.timestamp;
			} else {
				if(timestamp != element.timestamp) {
					throw new RuntimeException("iterator error");
				}
			}
			String[] schema = it.getOutputSchema();
			for(int i=0;i<schema.length;i++) {
				int pos = schemaMap.get(schema[i]);
				float value = element.data[i];
				if(!Float.isNaN(value)) {
					value_cnt[pos]++;
					value_sum[pos] += value;
				}
			}

		}
		float[] value_avg = new float[this.outputTimeSeriesSchema.columns];
		for(int i=0;i<this.outputTimeSeriesSchema.columns;i++) {
			if(value_cnt[i]>minCount) {
				value_avg[i] = value_sum[i]/value_cnt[i];
				//System.out.println("cnt: "+value_cnt[i]);
			} else {
				value_avg[i] = Float.NaN;
			}
		}
		return new TimeSeriesEntry(timestamp, value_avg);	
	}

	@Override
	public String getIteratorName() {
		return "AverageIterator";
	}

}
