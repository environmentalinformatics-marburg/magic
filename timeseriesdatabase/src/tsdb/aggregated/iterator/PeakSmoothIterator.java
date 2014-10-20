package tsdb.aggregated.iterator;

import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.raw.TsEntry;
import tsdb.util.TsSchema;
import tsdb.util.TsSchema.Aggregation;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.TsIterator;

/**
 * This iterator fills manually inserted sensor data with averaged values.
 * 
 * Input: 	mm
 * Output:	mm/h
 * 
 * 
 * 
 * @author woellauer
 *
 */
public class PeakSmoothIterator extends InputProcessingIterator {

	private static final int MAX_FILL_TIME_INTERVAL = 60*24*7*2;

	private static final int TIMESTEP=60;

	private final int columns;

	private long currentTimestamp;
	private float[] fillData;
	private long nextTimestamp;
	
	public static TsSchema createSchema(TsSchema tsSchema) {
		String[] names = tsSchema.names;
		Aggregation aggregation = Aggregation.CONSTANT_STEP;
		int timeStep = TIMESTEP;
		boolean isContinuous = false;
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false;
		boolean hasQualityCounters = false;
		return new TsSchema(names, aggregation, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters);		
	}

	public PeakSmoothIterator(TsIterator input_iterator) {
		super(input_iterator, createSchema(input_iterator.getSchema()));
		columns = input_iterator.getNames().length;
		if(input_iterator.hasNext()) {
			TsEntry first = input_iterator.next();	
			if(input_iterator.hasNext()) {
				TsEntry second = input_iterator.next();
				long deltaTime = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(second.timestamp)-(BaseAggregationTimeUtil.calcBaseAggregationTimestamp(first.timestamp)+TIMESTEP); //??				
				updateFillData(deltaTime,second.data);
				currentTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(first.timestamp) + TIMESTEP;
				nextTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(second.timestamp);
			} else {
				closed = true;				
			}			
		} else {
			closed = true;
		}
	}

	@Override
	protected TsEntry getNext() {
		if(currentTimestamp<=nextTimestamp) {
			return generateNext();
		} else {
			while(input_iterator.hasNext()) {
				TsEntry next = input_iterator.next();
				nextTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(next.timestamp);
				long deltaTime = nextTimestamp-(currentTimestamp-TIMESTEP);
				//System.out.println("delta time: "+deltaTime+" MAX_FILL_TIME_INTERVAL: "+MAX_FILL_TIME_INTERVAL);
				if(deltaTime<=MAX_FILL_TIME_INTERVAL) {
					updateFillData(deltaTime,next.data);
					return generateNext();
				}
				//System.out.println("big gap");
				currentTimestamp = nextTimestamp+TIMESTEP;
			}
			return null;
		}		
	}

	private void updateFillData(long deltaTime,float[] data) {
		fillData = new float[columns];
		for(int c=0;c<columns;c++) {
			fillData[c] = (data[c]/(deltaTime/TIMESTEP));
			//fillData[c] = (data[c]*60*24*7)/deltaTime;
		}
	}

	private TsEntry generateNext() {
		TsEntry result = new TsEntry(currentTimestamp, fillData);
		currentTimestamp += TIMESTEP;
		return result;
	}
}
