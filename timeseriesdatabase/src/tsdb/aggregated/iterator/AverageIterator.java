package tsdb.aggregated.iterator;

import static tsdb.util.AssumptionCheck.throwEmpty;

import java.util.Map;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TsSchema;
import tsdb.util.TsSchema.Aggregation;
import tsdb.util.Util;
import tsdb.util.iterator.MoveIterator;
import tsdb.util.iterator.NewProcessingChain;
import tsdb.util.iterator.NewProcessingChainMultiSources;
import tsdb.util.iterator.TsIterator;

/**
 * This iterator outputs elements of average values of input_iterator values.
 * input_iterators need to be in same timestamp per element order.
 * @author woellauer
 *
 */
public class AverageIterator extends MoveIterator {

	private Map<String, Integer> schemaMap;
	private TsIterator[] input_iterators;
	private final int minCount;

	private static TsSchema createSchema(String[] names, TsIterator[] input_iterators) {
		throwEmpty(input_iterators);
		TsSchema[] schemas = TsIterator.toSchemas(input_iterators);
		TsSchema.throwDifferentAggregation(schemas);
		Aggregation aggregation = schemas[0].aggregation;
		TsSchema.throwDifferentTimeStep(schemas);
		int timeStep = schemas[0].timeStep;
		TsSchema.throwDifferentContinuous(schemas);
		boolean isContinuous = schemas[0].isContinuous;
		return new TsSchema(names, aggregation,timeStep ,isContinuous);
	}

	public AverageIterator(String[] schema, TsIterator[] input_iterators, int minCount) {
		super(createSchema(schema, input_iterators));
		this.input_iterators = input_iterators;
		this.schemaMap = Util.stringArrayToMap(schema);
		this.minCount = minCount;
	}

	@Override
	protected TimeSeriesEntry getNext() {
		long timestamp = -1;
		int[] value_cnt = new int[this.schema.length];
		float[] value_sum = new float[this.schema.length];				
		for(TsIterator it:input_iterators) {
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
			String[] schema = it.getNames();
			for(int i=0;i<schema.length;i++) {
				int pos = schemaMap.get(schema[i]);
				float value = element.data[i];
				if(!Float.isNaN(value)) {
					value_cnt[pos]++;
					value_sum[pos] += value;
				}
			}

		}
		float[] value_avg = new float[this.schema.length];
		for(int i=0;i<this.schema.length;i++) {
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
	public NewProcessingChain getProcessingChain() {
		return new NewProcessingChainMultiSources(input_iterators, this);
	}
}
