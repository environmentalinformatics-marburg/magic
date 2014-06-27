package timeseriesdatabase.raw;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeSeriesDatabase;
import util.MoveIterator;
import util.SchemaIterator;

public class QualityCheckIterator extends MoveIterator<TimestampSeriesEntry> implements SchemaIterator<TimestampSeriesEntry> {

	private static final int MAX_TIME_STEP = 60;
	
	Iterator<TimestampSeriesEntry> input_iterator;
	int columns;
	long[] prevTimestamps;
	float[] prevData;
	
	boolean checkPhysicalRange;
	boolean checkEmpiricalRange;
	boolean checkStepRange;
	
	Sensor[] sensors;
	
	String[] schema;

	public QualityCheckIterator(TimeSeriesDatabase timeSeriesDatabase, SchemaIterator<TimestampSeriesEntry> input_iterator, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		this.checkPhysicalRange = checkPhysicalRange;
		this.checkEmpiricalRange = checkEmpiricalRange;
		this.checkStepRange = checkStepRange;
		
		this.schema = input_iterator.getOutputSchema();		
		sensors = timeSeriesDatabase.getSensors(input_iterator.getOutputSchema());
		
		columns = schema.length;
		this.input_iterator = input_iterator;
		this.prevTimestamps = new long[columns];
		this.prevData = new float[columns];
		for(int i=0;i<columns;i++) {
			prevTimestamps[i] = -1000;
			prevData[i] = Float.NaN; 
		}
	}

	@Override
	public TimestampSeriesEntry getNext() {
		while(input_iterator.hasNext()) {
			TimestampSeriesEntry currEntry = input_iterator.next();
			long currTimestamp = currEntry.timestamp;
			float[] currData = currEntry.data;
			float[] resultData = new float[columns]; 
			int validColumnCounter = 0;
			for(int columnIndex=0;columnIndex<columns;columnIndex++) {
				float currValue = currData[columnIndex];
				if(Float.isNaN(currValue)) {
					if(currTimestamp<=prevTimestamps[columnIndex]+MAX_TIME_STEP) { // perform step check
						float prevValue = prevData[columnIndex];
						if(!checkStepRange||sensors[columnIndex].checkStepRange(prevValue, currValue)) { //step check successful
							resultData[columnIndex] = currValue;
							validColumnCounter++;
							prevTimestamps[columnIndex] = currTimestamp;
							prevData[columnIndex] = currValue;
						} else { // data value out of step range
							resultData[columnIndex] = Float.NaN;
						}

					} else { // "valid" data, not step checked
						resultData[columnIndex] = currValue;
						validColumnCounter++;
						prevTimestamps[columnIndex] = currTimestamp;
						prevData[columnIndex] = currValue;
					}
				} else { // no data value
					resultData[columnIndex] = Float.NaN;
				}
			}
			if(validColumnCounter>0) {
				return new TimestampSeriesEntry(currTimestamp, resultData);
			}			
		}		
		return null; // no element left
	}

	@Override
	public String[] getOutputSchema() {
		return schema;
	}
}
