package tsdb.aggregated.iterator;

import java.util.List;

import tsdb.DataQuality;
import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsSchema;
import tsdb.util.TsSchema.Aggregation;
import tsdb.util.iterator.NewProcessingChain;
import tsdb.util.iterator.NewProcessingChainMultiSources;
import tsdb.util.iterator.TsIterator;

/**
 * This iterator checks values of input_iterator by comparing values to compare_iterator.
 * If value is higher than maxDiff a nan value is inserted. 
 * @author woellauer
 *
 */
public class EmpiricalIterator extends TsIterator {

	private TsIterator input_iterator;
	private TsIterator compare_iterator;
	private Float[] maxDiff;

	public static TsSchema createSchema(TsSchema schema) {
		schema.throwNotContinuous();
		boolean isContinuous = true;
		schema.throwNoConstantTimeStep();
		Aggregation aggregation = Aggregation.CONSTANT_STEP;
		schema.throwNoBaseAggregation();
		int timeStep = BaseAggregationTimeUtil.AGGREGATION_TIME_INTERVAL;
		//TODO quality flag
		return new TsSchema(schema.names, aggregation, timeStep, isContinuous);
	}

	public EmpiricalIterator(TsIterator input_iterator, TsIterator compare_iterator, Float[] maxDiff) {
		super(createSchema(input_iterator.getSchema()));
		this.input_iterator = input_iterator;
		this.compare_iterator = compare_iterator;
		this.maxDiff = maxDiff;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		TimeSeriesEntry element = input_iterator.next();
		TimeSeriesEntry genElement = compare_iterator.next();
		long timestamp = element.timestamp;
		if(timestamp!= genElement.timestamp) {
			throw new RuntimeException("iterator error");
		}

		float[] result = new float[schema.length];
		DataQuality[] resultQf = new DataQuality[schema.length];
		for(int colIndex=0;colIndex<schema.length;colIndex++) {
			if(element.qualityFlag[colIndex]==DataQuality.STEP) {
				if(maxDiff[colIndex]!=null&&!Float.isNaN(genElement.data[colIndex])) {
					if(Math.abs(element.data[colIndex]-genElement.data[colIndex])<=maxDiff[colIndex]) { // check successful
						resultQf[colIndex] = DataQuality.EMPIRICAL;
						result[colIndex] = element.data[colIndex];
					} else { // remains STEP
						resultQf[colIndex] = DataQuality.STEP;
						result[colIndex] = Float.NaN;
					}
				} else { // no check possible
					resultQf[colIndex] = DataQuality.EMPIRICAL;
					result[colIndex] = element.data[colIndex];
				}
			} else {
				resultQf[colIndex] = element.qualityFlag[colIndex]; // Na, NO or PYSICAL 
				result[colIndex] = Float.NaN;
			}
			//System.out.println(element.qualityFlag[colIndex]+"  "+element.data[colIndex]+":  "+genElement.data[colIndex]+"  "+maxDiff[colIndex]+" -> "+Math.abs(result[colIndex]-genElement.data[colIndex])+"  "+resultQf[colIndex]+"  "+result[colIndex]);
		}





		/*
		float[] result = new float[outputTimeSeriesSchema.columns];
		for(int colIndex=0;colIndex<outputTimeSeriesSchema.columns;colIndex++) {
			result[colIndex] = element.data[colIndex];			
			if(!Float.isNaN(genElement.data[colIndex])) { // general values is not nan
				if(!Float.isNaN(element.data[colIndex])) { // value is not nan
					Float maxdiff = maxDiff[colIndex];
					if(maxdiff!=null) { // maxDiff value is present
						float diff = Math.abs(element.data[colIndex]-genElement.data[colIndex]);
						if(maxdiff<diff) { // passed not empirical check
							result[colIndex] = Float.NaN;
						}
					} 
				} 
			}			
		}*/


		return new TimeSeriesEntry(timestamp,result);
	}

	@Override
	public NewProcessingChain getProcessingChain() {
		return new NewProcessingChainMultiSources(new TsIterator[]{input_iterator,compare_iterator}, this);
	}
}
