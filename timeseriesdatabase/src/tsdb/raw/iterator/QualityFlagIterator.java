package tsdb.raw.iterator;

import java.util.List;

import tsdb.DataQuality;
import tsdb.Sensor;
import tsdb.TsDB;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.MoveIterator;
import tsdb.util.iterator.TsIterator;

/**
 * adds Quality flags to input data
 * @author woellauer
 *
 */
public class QualityFlagIterator extends InputProcessingIterator {

	private static final int MAX_TIME_STEP = 60;
	
	long[] prevTimestamps;
	float[] prevData;
	
	Sensor[] sensors;

	public QualityFlagIterator(TsDB timeSeriesDatabase, TsIterator input_iterator) {
		super(input_iterator, TimeSeriesSchema.createWithQualityFlags(input_iterator.getSchema().toTimeSeriesSchema()).toTsSchema());	
		sensors = timeSeriesDatabase.getSensors(input_iterator.getNames());
		this.prevTimestamps = new long[schema.length];
		this.prevData = new float[schema.length];
		for(int i=0;i<schema.length;i++) {
			prevTimestamps[i] = -1000;
			prevData[i] = Float.NaN; 
		}
	}
	
	@Override
	public TimeSeriesEntry getNext() {
		if(input_iterator.hasNext()) {
			TimeSeriesEntry currEntry = input_iterator.next();
			long currTimestamp = currEntry.timestamp;
			float[] currData = currEntry.data;
			DataQuality[] flags = new DataQuality[schema.length];
			for(int columnIndex=0;columnIndex<schema.length;columnIndex++) {
				float currValue = currData[columnIndex];
				Sensor sensor = sensors[columnIndex];
				DataQuality currQuality = DataQuality.Na;
				if(!Float.isNaN(currValue)) {
					currQuality = DataQuality.NO;
					if(sensor.checkPhysicalRange(currValue)) {
						currQuality = DataQuality.PHYSICAL;
						long timewindow = prevTimestamps[columnIndex]+MAX_TIME_STEP;
						if( (!(currTimestamp<=timewindow))||sensor.checkStepRange(prevData[columnIndex], currValue)) {//step check
							currQuality = DataQuality.STEP;
							/*if(sensor.checkEmpiricalRange(currValue)) { // no empirical check here!
								currQuality = DataQuality.EMPIRICAL;
							}*/
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
}

