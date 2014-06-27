package timeseriesdatabase.raw;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeSeriesDatabase;

public class RawDataQualityCheckProcessor {

	private static final int MAX_TIME_STEP = 60;
	
	Iterator<TimestampSeriesEntry> input_iterator;
	int columns;
	long[] prevTimestamps;
	float[] prevData;
	
	boolean checkPhysicalRange;
	boolean checkEmpiricalRange;
	boolean checkStepRange;
	
	Sensor[] sensors;
	
	ArrayList<TimestampSeriesEntry> resultList;
	
	TimestampSeries timestampSeries;


	RawDataQualityCheckProcessor(TimeSeriesDatabase timeSeriesDatabase, TimestampSeries timestampSeries, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		this.timestampSeries = timestampSeries;
		
		this.checkPhysicalRange = checkPhysicalRange;
		this.checkEmpiricalRange = checkEmpiricalRange;
		this.checkStepRange = checkStepRange;
		
		
		sensors = timeSeriesDatabase.getSensors(timestampSeries.parameterNames);



		columns = timestampSeries.parameterNames.length;
		resultList = new ArrayList<TimestampSeriesEntry>();
		input_iterator = timestampSeries.entryList.iterator();
		long[] prevTimestamps = new long[columns];
		float[] prevData = new float[columns];
		for(int i=0;i<columns;i++) {
			prevTimestamps[i] = -1000;
			prevData[i] = Float.NaN; 
		}		



	}

	public TimestampSeries process() {




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
				resultList.add(new TimestampSeriesEntry(currTimestamp, currData));
			}			
		}		
		return new TimestampSeries(timestampSeries.parameterNames, resultList, null);

	}


	public void getNext() {

	}









}
