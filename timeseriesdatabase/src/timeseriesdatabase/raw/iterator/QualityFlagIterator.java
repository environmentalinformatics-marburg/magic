package timeseriesdatabase.raw.iterator;

import java.util.Iterator;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.TimeSeriesSchema;
import util.iterator.MoveIterator;
import util.iterator.TimeSeriesIterator;

public class QualityFlagIterator extends MoveIterator {

	private static final int MAX_TIME_STEP = 60;
	
	Iterator<TimeSeriesEntry> input_iterator;
	int columns;
	long[] prevTimestamps;
	float[] prevData;
	
	Sensor[] sensors;
	
	String[] schema;

	public QualityFlagIterator(TimeSeriesDatabase timeSeriesDatabase, TimeSeriesIterator input_iterator) {
		super(new TimeSeriesSchema(input_iterator.getOutputTimeSeriesSchema().schema));

		
		this.schema = input_iterator.getOutputSchema();		
		sensors = timeSeriesDatabase.getSensors(input_iterator.getOutputTimeSeriesSchema());
		
		columns = schema.length;
		this.input_iterator = input_iterator;
		this.prevTimestamps = new long[columns];
		this.prevData = new float[columns];
		for(int i=0;i<columns;i++) {
			prevTimestamps[i] = -1000;
			prevData[i] = Float.NaN; 
		}
	}
	
	public enum DataQualtity { NO, PHYSICAL, STEP, EMPIRICAL};
	
	@Override
	public TimeSeriesEntry getNext() {
		if(input_iterator.hasNext()) {
			TimeSeriesEntry currEntry = input_iterator.next();
			long currTimestamp = currEntry.timestamp;
			float[] currData = currEntry.data;
			DataQualtity[] flags = new DataQualtity[columns];
			for(int columnIndex=0;columnIndex<columns;columnIndex++) {
				float currValue = currData[columnIndex];
				Sensor sensor = sensors[columnIndex];
				DataQualtity currQuality = DataQualtity.NO;
				if(!Float.isNaN(currValue)) {
					if(sensor.checkPhysicalRange(currValue)) {
						currQuality = DataQualtity.PHYSICAL;
						long timewindow = prevTimestamps[columnIndex]+MAX_TIME_STEP;
						if( (!(currTimestamp<=timewindow))||sensor.checkStepRange(prevData[columnIndex], currValue)) {//step check
							currQuality = DataQualtity.STEP;
							if(sensor.checkEmpiricalRange(currValue)) {
								currQuality = DataQualtity.EMPIRICAL;
							}
						} 					
					}
					//if value is not NaN store element in prev
					prevTimestamps[columnIndex] = currTimestamp;
					prevData[columnIndex] = currValue;
				}
				flags[columnIndex] = currQuality;
			}
			return new TimeSeriesEntry(currTimestamp, currData, flags);
		} else {
			return null; // no elements left
		}
	}

	@Override
	public String[] getOutputSchema() {
		return schema;
	}
}

