package tsdb.aggregated.iterator;

import tsdb.TimeConverter;
import tsdb.raw.TimeSeriesEntry;
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

	private final int timeStep=60;

	private final int columns;

	private long currentTimestamp;
	private float[] fillData;
	private long nextTimestamp;

	public PeakSmoothIterator(TimeSeriesIterator input_iterator) {
		super(input_iterator, input_iterator.getOutputTimeSeriesSchema()/*TODO*/);
		columns = input_iterator.getOutputSchema().length;
		if(input_iterator.hasNext()) {
			TimeSeriesEntry first = input_iterator.next();
			if(input_iterator.hasNext()) {
				TimeSeriesEntry second = input_iterator.next();
				long deltaTime = second.timestamp-(first.timestamp+timeStep); //??				
				updateFillData(deltaTime,second.data);
				currentTimestamp = first.timestamp + timeStep;
				nextTimestamp = second.timestamp;
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
				nextTimestamp = next.timestamp;
				long deltaTime = nextTimestamp-(currentTimestamp-timeStep);
				//System.out.println("delta time: "+deltaTime+" MAX_FILL_TIME_INTERVAL: "+MAX_FILL_TIME_INTERVAL);
				if(deltaTime<=MAX_FILL_TIME_INTERVAL) {
					updateFillData(deltaTime,next.data);
					return generateNext();
				}
				//System.out.println("big gap");
				currentTimestamp = nextTimestamp+timeStep;
			}
			return null;
		}		
	}

	private void updateFillData(long deltaTime,float[] data) {
		fillData = new float[columns];
		for(int c=0;c<columns;c++) {
			fillData[c] = (data[c]/(deltaTime/timeStep));
		}
	}

	private TimeSeriesEntry generateNext() {
		TimeSeriesEntry result = new TimeSeriesEntry(currentTimestamp, fillData);
		currentTimestamp += timeStep;
		return result;
	}
}
