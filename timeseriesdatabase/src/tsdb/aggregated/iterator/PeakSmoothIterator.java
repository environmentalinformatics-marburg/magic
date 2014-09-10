package tsdb.aggregated.iterator;

import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.TimeSeriesIterator;

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
	
	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = true;
		boolean isContinuous = false;		
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false;
		boolean hasQualityCounters = false;
		return new TimeSeriesSchema(schema, constantTimeStep, TIMESTEP, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;

	}

	public PeakSmoothIterator(TimeSeriesIterator input_iterator) {
		super(input_iterator, createSchema(input_iterator.getOutputTimeSeriesSchema()));
		columns = input_iterator.getOutputSchema().length;
		if(input_iterator.hasNext()) {
			TimeSeriesEntry first = input_iterator.next();	
			if(input_iterator.hasNext()) {
				TimeSeriesEntry second = input_iterator.next();
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
	protected TimeSeriesEntry getNext() {
		if(currentTimestamp<=nextTimestamp) {
			return generateNext();
		} else {
			while(input_iterator.hasNext()) {
				TimeSeriesEntry next = input_iterator.next();
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
			//fillData[c] = (data[c]/(deltaTime/timeStep));
			fillData[c] = (data[c]*60*24*7)/deltaTime;
		}
	}

	private TimeSeriesEntry generateNext() {
		TimeSeriesEntry result = new TimeSeriesEntry(currentTimestamp, fillData);
		currentTimestamp += TIMESTEP;
		return result;
	}
}
