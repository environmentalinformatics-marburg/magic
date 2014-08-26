package tsdb.aggregated.iterator;

import java.util.List;

import tsdb.DataQuality;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.iterator.TimeSeriesIterator;

/**
 * This iterator checks values of input_iterator by comparing values to compare_iterator.
 * If value is higher than maxDiff a nan value is inserted. 
 * @author woellauer
 *
 */
public class EmpiricalIterator extends TimeSeriesIterator {

	private TimeSeriesIterator input_iterator;
	private TimeSeriesIterator compare_iterator;
	private Float[] maxDiff;

	public static TimeSeriesSchema createSchema(TimeSeriesIterator input_iterator) {
		TimeSeriesSchema input_schema = input_iterator.getOutputTimeSeriesSchema();
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;
		if(!input_schema.hasQualityFlags) {
			throw new RuntimeException("no quality flags in schema");
		}
		boolean hasQualityFlags = true;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}

	public EmpiricalIterator(TimeSeriesIterator input_iterator, TimeSeriesIterator compare_iterator, Float[] maxDiff) {
		super(createSchema(input_iterator));
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

		float[] result = new float[outputTimeSeriesSchema.columns];
		DataQuality[] resultQf = new DataQuality[outputTimeSeriesSchema.columns];
		for(int colIndex=0;colIndex<outputTimeSeriesSchema.columns;colIndex++) {
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
		public List<ProcessingChainEntry> getProcessingChain() {
			List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
			result.add(this);
			return result;
		}
	}
