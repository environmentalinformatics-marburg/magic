package timeseriesdatabase;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;

import org.apache.logging.log4j.Logger;

import util.Util;

public class BaseTimeSeries {
	
	private static final Logger log = Util.log;
	
	public String[] parameterNames;
	
	long startTimestamp;
	public int timeStep;
	
	public float[][] data;
	
	public BaseTimeSeries(String[] parameterNames, long startTimestamp, int timeStep, float[][] data) {
		this.parameterNames = parameterNames;
		this.startTimestamp = startTimestamp;
		this.timeStep = timeStep;
		this.data = data;
	}
	
	public static BaseTimeSeries toBaseTimeSeries(long startTimestamp, long endTimestamp, TimeSeries timeSeries) {
		if(timeSeries.timeinterval==null) {
			log.error("TimeSeries needs to be aggregated for BaseTimeSeries creation");
		}		
		int timeStep = timeSeries.timeinterval;
		if(endTimestamp<startTimestamp) {
			log.error("error");
		}
		if((endTimestamp-startTimestamp)%timeStep!=0) {
			log.error("error");
		}
		
		Iterator<TimeSeriesEntry> it = timeSeries.entryList.iterator();
		TimeSeriesEntry nextEntry;		
		if(it.hasNext()) {
			nextEntry = it.next();
			if(nextEntry.timestamp%timeStep!=0) {
				log.error("wrong data");
			}
		} else {
		    nextEntry = null;
		}
		
		while(nextEntry!=null&&nextEntry.timestamp<startTimestamp) {
			if(it.hasNext()) {
				nextEntry = it.next();
				if(nextEntry.timestamp%timeStep!=0) {
					log.error("wrong data");
				}
			} else {
			    nextEntry = null;
			}
		}
		
		float[][] resultData = new float[timeSeries.parameterNames.length][(int) ((endTimestamp-startTimestamp)/timeStep)+1];
		int dataIndex=0;
		for(long timestamp=startTimestamp;timestamp<=endTimestamp;timestamp+=timeStep) {
			if(nextEntry!=null&&nextEntry.timestamp==timestamp) {
				// insert row
				for(int columnIndex=0;columnIndex<timeSeries.parameterNames.length;columnIndex++) {
					resultData[columnIndex][dataIndex] = nextEntry.data[columnIndex];
					if(it.hasNext()) {
						nextEntry = it.next();
						if(nextEntry.timestamp%timeStep!=0) {
							log.error("wrong data");
						}
					} else {
					    nextEntry = null;
					}
				}
			} else if(nextEntry!=null&&nextEntry.timestamp<timestamp) {
				log.error("error: nextEntry.timestamp "+nextEntry.timestamp+"\t timestamp"+timestamp);
			} else {
				// insert NaN
				for(int columnIndex=0;columnIndex<timeSeries.parameterNames.length;columnIndex++) {
					resultData[columnIndex][dataIndex] = Float.NaN;					
				}
			}
			dataIndex++;
		}
		
		return new BaseTimeSeries(timeSeries.parameterNames, startTimestamp, timeStep, resultData);
		
		
		
		/*
		if(timeSeries.timeinterval==null) {
			log.error("TimeSeries needs to be aggregated for BaseTimeSeries creation");
		}
		Integer timeinterval = timeSeries.timeinterval;
		List<TimeSeriesEntry> gapList = new ArrayList<TimeSeriesEntry>();
		
		Iterator<TimeSeriesEntry> it = timeSeries.entryList.iterator();
		TimeSeriesEntry nextEntry = null;		
		if(it.hasNext()) {
			nextEntry = it.next();			
		} else {
		    nextEntry = null;
		}		
		
		for(long timestamp=startTimestamp; timestamp<=endTimestamp; timestamp+=timeinterval) {			
			if(nextEntry != null&&nextEntry.timestamp==timestamp) {
				gapList.add(nextEntry);
				if(it.hasNext()) {
					nextEntry = it.next();
				} else {
					nextEntry = null;
				}
			} else if(nextEntry != null&&nextEntry.timestamp<timestamp) {
				log.error("error");
			} else {
				float[] gapData = new float[timeSeries.parameterNames.length];
				for(int i=0;i<timeSeries.parameterNames.length;i++) {
					gapData[i] = Float.NaN;
				}
				gapList.add(new TimeSeriesEntry(timestamp, gapData));
			}			
		}
		
		if(it.hasNext()) {
			log.error("some data left");
		}
		
		float[][] data = new float[timeSeries.parameterNames.length][gapList.size()];
		for(int offset=0;offset<gapList.size();offset++) {
			TimeSeriesEntry entry = gapList.get(offset);
			for(int parameterIndex=0;parameterIndex<timeSeries.parameterNames.length;parameterIndex++) {
				if(startTimestamp+offset*timeinterval != entry.timestamp) {
					log.error("timestamp error in BaseTimeSeries");
				}
				data[parameterIndex][offset] = entry.data[parameterIndex];				
			}
		}
		
		return new BaseTimeSeries(timeSeries.parameterNames, startTimestamp, timeinterval, data);*/	
	}
	
	public String toString() {
		return "BaseTimeSeries: "+startTimestamp+"\t"+timeStep+"\t"+data.length+"\t"+data[0].length;
	}
	
	public void writeToCSV(String filename, String separator, String nanText, CSVTimeType csvTimeType) {
		boolean time=false;
		if(csvTimeType==CSVTimeType.TIMESTAMP||csvTimeType==CSVTimeType.DATETIME||csvTimeType==CSVTimeType.TIMESTAMP_AND_DATETIME) {
			time=true;
		}
		try {
			PrintStream printStream = new PrintStream(filename);
			if(time) {
				switch(csvTimeType) {
				case TIMESTAMP:
					printStream.print("timestamp");
					break;
				case DATETIME:
					printStream.print("datetime");
					break;
				case TIMESTAMP_AND_DATETIME:
					printStream.print("timestamp");
					printStream.print(separator);
					printStream.print("datetime");
					break;
				default:
					printStream.print("???");
				}
			}
			for(int i=0;i<parameterNames.length;i++) {
				if(time||i>0) {
					printStream.print(separator);
				}
				printStream.print(parameterNames[i]);				
			}
			printStream.println();
			for(int rowIndex=0;rowIndex<data[0].length;rowIndex++) {
				long timestamp = startTimestamp+rowIndex*timeStep;
			//for(TimeSeriesEntry entry:entryList) {
				if(time) {
					switch(csvTimeType) {
					case TIMESTAMP:
						printStream.print(timestamp);
						break;
					case DATETIME:
						printStream.print(TimeConverter.oleMinutesToLocalDateTime(timestamp));
						break;
					case TIMESTAMP_AND_DATETIME:
						printStream.print(timestamp);
						printStream.print(separator);
						printStream.print(TimeConverter.oleMinutesToLocalDateTime(timestamp));
						break;
					default:
						printStream.print("---");
					}
				}
				for(int columnIndex=0;columnIndex<data.length;columnIndex++) {
					float value = data[columnIndex][rowIndex];
					if(time||columnIndex>0) {
						printStream.print(separator);
					}
					if(Float.isNaN(value)) {
						printStream.print(nanText);
					} else {
						//s+=Util.floatToString(entry.data[i]);
						printStream.format(Locale.ENGLISH,"%3.3f", value);
					}
				}
				printStream.println();
			}
			printStream.close();
		} catch (FileNotFoundException e) {
			log.error(e);
		}
	}
	
	public int getParameterNameIndex(String parameterName) {
		return Util.StringArrayToMap(parameterNames).get(parameterName);
		
	}
	
	public float[] getValues(String parameterName) {
		return data[getParameterNameIndex(parameterName)];
	}
	
	public BaseTimeSeries getClipped(long clipStartTimestamp, long clipEndTimestamp) {
		if(clipStartTimestamp>clipEndTimestamp) {
			log.error("wrong data");
			return null;
		}
		if(clipStartTimestamp%timeStep!=0||clipEndTimestamp%timeStep!=0) {
			log.error("timeststamps not alligned");
			return null;			
		}
		float[][] resultData = new float[parameterNames.length][(int) (((clipEndTimestamp-clipStartTimestamp)/timeStep)+1)];
		for(long timestamp=clipStartTimestamp;timestamp<=clipEndTimestamp;timestamp+=timeStep) {
			if(timestamp<startTimestamp || timestamp>startTimestamp+(this.data[0].length*timeStep)) {
				for(int i=0; i<parameterNames.length; i++) {
					resultData[i][(int) ((timestamp-clipStartTimestamp)/timeStep)] = Float.NaN;
				}
			} else {
				for(int i=0; i<parameterNames.length; i++) {
					resultData[i][(int) ((timestamp-clipStartTimestamp)/timeStep)] = this.data[i][(int) ((timestamp-startTimestamp)/timeStep)];
				}
			}
		}
		return new BaseTimeSeries(this.parameterNames, clipStartTimestamp, timeStep, resultData);
	}

}
