package timeseriesdatabase.raw.iterator;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.MoveIterator;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;

@Deprecated
public class QualityCheckIterator extends MoveIterator {

	private static final int MAX_TIME_STEP = 60;
	
	TimeSeriesIterator input_iterator;
	int columns;
	long[] prevTimestamps;
	float[] prevData;
	
	boolean checkPhysicalRange;
	boolean checkEmpiricalRange;
	boolean checkStepRange;
	
	Sensor[] sensors;
	
	String[] schema;

	public QualityCheckIterator(TimeSeriesDatabase timeSeriesDatabase, TimeSeriesIterator input_iterator, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		super(new TimeSeriesSchema(input_iterator.getOutputTimeSeriesSchema().schema));
		this.checkPhysicalRange = checkPhysicalRange;
		this.checkEmpiricalRange = checkEmpiricalRange;
		this.checkStepRange = checkStepRange;
		
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

	@Override
	public TimeSeriesEntry getNext() {
		while(input_iterator.hasNext()) {
			TimeSeriesEntry currEntry = input_iterator.next();
			long currTimestamp = currEntry.timestamp;
			float[] currData = currEntry.data;
			float[] resultData = new float[columns]; 
			int validColumnCounter = 0;
			for(int columnIndex=0;columnIndex<columns;columnIndex++) {
				float currValue = currData[columnIndex];
				if(!Float.isNaN(currValue)) {					
					if(!checkPhysicalRange||sensors[columnIndex].checkPhysicalRange(currValue)) {					
					if(!checkEmpiricalRange||sensors[columnIndex].checkEmpiricalRange(currValue)) {					
					if(currTimestamp<=prevTimestamps[columnIndex]+MAX_TIME_STEP) { // perform step check
						float prevValue = prevData[columnIndex];
						if(!checkStepRange||sensors[columnIndex].checkStepRange(prevValue, currValue)) { //step check successful
							resultData[columnIndex] = currValue;
							validColumnCounter++;
							prevTimestamps[columnIndex] = currTimestamp;
							prevData[columnIndex] = currValue;
						} else { // data value out of step range
							System.out.println("data value out of step range"+currValue+" in "+schema[columnIndex]+" at "+ TimeConverter.oleMinutesToLocalDateTime(currTimestamp)+"step range: "+sensors[columnIndex].stepMin+" "+sensors[columnIndex].stepMax);
							resultData[columnIndex] = Float.NaN;
						}
					} else { // "valid" data, not step checked
						resultData[columnIndex] = currValue;
						validColumnCounter++;
						prevTimestamps[columnIndex] = currTimestamp;
						prevData[columnIndex] = currValue;
					}
					
					} else { // data value out of empirical range
						//System.out.println("data value out of physical range"+currValue+" in "+schema[columnIndex]+" at "+TimeConverter.oleMinutesToLocalDateTime(currTimestamp));
						resultData[columnIndex] = Float.NaN;
					}
					
					
					} else { // data value out of physical range
						//System.out.println("data value out of physical range: "+currValue+" in "+schema[columnIndex]+" at "+TimeConverter.oleMinutesToLocalDateTime(currTimestamp));
						resultData[columnIndex] = Float.NaN;
					}
					
					
				} else { // no data value
					resultData[columnIndex] = Float.NaN;
				}
			}
			if(validColumnCounter>0) {
				return new TimeSeriesEntry(currTimestamp, resultData);
			}			
		}		
		return null; // no element left
	}

	@Override
	public String[] getOutputSchema() {
		return schema;
	}

	@Override
	public String getIteratorName() {
		return "QualityCheckIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}
}
