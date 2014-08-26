package tsdb.aggregated.iterator;

import java.util.List;
import java.util.Map;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.Util;
import tsdb.util.iterator.MoveIterator;
import tsdb.util.iterator.TimeSeriesIterator;

@Deprecated
public class EmpiricalIterator_OLD extends MoveIterator {
	
	private final TimeSeriesIterator input_iterator;
	private final TimeSeriesIterator[] compareIterators;
	private final Float[] maxDiff;
	
	private final int columns;	
	private int[][] posIndex;
	
	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}

	/**
	 * 
	 * @param input_iterator
	 * @param compareIterators
	 * @param maxDiff null entries are not used for empirical checks
	 */
	public EmpiricalIterator_OLD(TimeSeriesIterator input_iterator, TimeSeriesIterator[] compareIterators, Float[] maxDiff) {
		super(createSchema(input_iterator.getOutputTimeSeriesSchema()));
		this.input_iterator = input_iterator;
		this.compareIterators = compareIterators;
		this.maxDiff = maxDiff;
		
		this.columns = input_iterator.getOutputSchema().length;
		this.posIndex = new int[compareIterators.length][columns];
		
		String[] schema = this.outputTimeSeriesSchema.schema;
		for(int itIndex=0;itIndex<compareIterators.length;itIndex++) {
			Map<String, Integer> map = Util.stringArrayToMap(compareIterators[itIndex].getOutputSchema());  
			for(int colIndex=0;colIndex<columns;colIndex++) {
				if(maxDiff!=null) {
					Integer attrNr = map.get(schema[colIndex]);
					if(attrNr!=null) {
						posIndex[itIndex][colIndex] = attrNr;
					} else {
						attrNr = -1;
					}
				} else {
					posIndex[itIndex][colIndex] = -1;
				}
			}
		}
		
		
	}
	
	@Override
	protected TimeSeriesEntry getNext() {
		
		if(!input_iterator.hasNext()) {
			return null;
		}
		TimeSeriesEntry element = input_iterator.next();
		
		//float[] diff = new float[columns];
		float[] sum = new float[columns];
		int[] cnt = new int[columns];
		for(int colIndex=0;colIndex<columns;colIndex++) {
			sum[colIndex] = 0;
			cnt[colIndex] = 0;
		}
		
		for(int itIndex=0;itIndex<compareIterators.length;itIndex++) {
			if(!compareIterators[itIndex].hasNext()) {
				throw new RuntimeException("iterator error");
			}
			float[] compare = compareIterators[itIndex].next().data;
			for(int colIndex=0;colIndex<columns;colIndex++) {
				int pos = posIndex[itIndex][colIndex];
				if(pos!=-1) {					
					if(!Float.isNaN(element.data[colIndex])) {
						if(!Float.isNaN(compare[pos])) {
							sum[colIndex] = Math.abs(compare[pos]-element.data[colIndex]);
							cnt[colIndex]++;
						}
					}
				}
			}
		}
		
		float[] resultData = new float[columns];
		for(int colIndex=0;colIndex<columns;colIndex++) {
			if(maxDiff[colIndex] != null && cnt[colIndex]>0) {
				float diff = sum[colIndex]/cnt[colIndex];
				//System.out.println("diff: "+diff);
				if(diff<=maxDiff[colIndex]) {
					resultData[colIndex] = element.data[colIndex];
				} else {
					resultData[colIndex] = Float.NaN;
				}
			} else {
				resultData[colIndex] = element.data[colIndex];
			}
		}
		
		return new TimeSeriesEntry(element.timestamp, resultData);		
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}

	@Override
	public String getIteratorName() {
		return "EmpiricalIterator";
	}

}
