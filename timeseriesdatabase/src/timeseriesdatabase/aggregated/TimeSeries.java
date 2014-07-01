package timeseriesdatabase.aggregated;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimestampSeriesEntry;
import util.SchemaIterator;
import util.TimeSeriesIterator;
import util.TimeSeriesSchema;
import util.Util;

/**
 * time series of aggregated data. time interval between values is constant
 * @author woellauer
 *
 */
public class TimeSeries {
	
	private static final Logger log = Util.log;
	
	/**
	 * sensor names of time series in data
	 */
	public String[] parameterNames;
	
	/**
	 * timestamp of first entry in data
	 */
	public long startTimestamp;
	
	/**
	 * constant time step between entries
	 */
	public final int timeStep;
	
	/**
	 * time series data values:
	 * data [ sensor index ]  [ row index ]
	 */
	public float[][] data;
	
	public TimeSeries(String[] parameterNames, long startTimestamp, int timeStep, float[][] data) {
		this.parameterNames = parameterNames;
		this.startTimestamp = startTimestamp;
		this.timeStep = timeStep;
		this.data = data;
	}
	
	/**
	 * Converts elements of an iterator in TimeSeries object.
	 * Elements need to be in ordered in timeStep time intervals
	 * @param input_iterator
	 * @param timeStep
	 * @return
	 */
	public static TimeSeries toBaseTimeSeries(SchemaIterator<TimestampSeriesEntry> input_iterator) {
		TimeSeriesSchema timeSeriesSchema = input_iterator.getOutputTimeSeriesSchema();
		if(!timeSeriesSchema.constantTimeStep) {
			log.error("time series needs to have constant aggregated timesteps");
			return null;
		}
		if(!timeSeriesSchema.isContinuous) {
			log.error("time series needs to have constant timesteps and continuous entries");
			return null;
		}
		String[] schema = timeSeriesSchema.schema;
		
		if(!input_iterator.hasNext()) {
			return null; // not data in input_iterator
		}
		
		ArrayList<TimestampSeriesEntry> entryList = Util.iteratorToList(input_iterator);		
		long startTimestamp = entryList.get(0).timestamp;		
		float[][] data = new float[schema.length][entryList.size()];
		
		long timestamp=-1;
		for(int i=0;i<entryList.size();i++) {
			TimestampSeriesEntry entry = entryList.get(i);
			if(timestamp==-1||timestamp+timeSeriesSchema.timeStep==entry.timestamp) {
			for(int column=0;column<schema.length;column++) {
				data[column][i] = entry.data[column];
			}
			} else {
				log.error("timestamps are not in timestep intervals");
				return null;
			}
			timestamp = entry.timestamp;
		}
		
		return new TimeSeries(schema, startTimestamp, timeSeriesSchema.timeStep, data);
		
	}
	
	/**
	 * converts TimestampSeries to TimeSeries
	 * missing values before and after data in source time series and gaps within source timeseries are filled with NaN-values
	 * source time series needs to be aggregated already
	 * @param startTimestamp timestamp of first entry in resulting time series
	 * @param endTimestamp timestamp of last entry in resulting time series
	 * @param timestampSeries
	 * @return null if conversion is not possible
	 */
	public static TimeSeries toBaseTimeSeries(Long startTimestamp, Long endTimestamp, TimestampSeries timestampSeries) {
		if(startTimestamp==null) {
			startTimestamp = timestampSeries.getFirstTimestamp();
		}
		if(endTimestamp==null) {
			endTimestamp = timestampSeries.getLastTimestamp();
		}
		
		if(timestampSeries.timeinterval==null) {
			log.error("TimeSeries needs to be aggregated for BaseTimeSeries creation");
		}		
		int timeStep = timestampSeries.timeinterval;
		if(endTimestamp<startTimestamp) {
			log.error("error");
		}
		if((endTimestamp-startTimestamp)%timeStep!=0) {
			log.error("error");
		}
		
		Iterator<TimestampSeriesEntry> it = timestampSeries.entryList.iterator();
		TimestampSeriesEntry nextEntry;		
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
		
		float[][] resultData = new float[timestampSeries.parameterNames.length][(int) ((endTimestamp-startTimestamp)/timeStep)+1];
		int dataIndex=0;
		for(long timestamp=startTimestamp;timestamp<=endTimestamp;timestamp+=timeStep) {
			if(nextEntry!=null&&nextEntry.timestamp==timestamp) {
				// insert row
				for(int columnIndex=0;columnIndex<timestampSeries.parameterNames.length;columnIndex++) {
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
				for(int columnIndex=0;columnIndex<timestampSeries.parameterNames.length;columnIndex++) {
					resultData[columnIndex][dataIndex] = Float.NaN;					
				}
			}
			dataIndex++;
		}
		
		return new TimeSeries(timestampSeries.parameterNames, startTimestamp, timeStep, resultData);
	}
	
	/**
	 * some summary data of this time series
	 */
	public String toString() {
		return "BaseTimeSeries: "+startTimestamp+"\t"+timeStep+"\t"+data.length+"\t"+data[0].length;
	}
	
	/**
	 * write timeseries to CSV-file
	 * @param filename
	 * @param separator seperator between values
	 * @param nanText text output of NaN-values
	 * @param csvTimeType time columns that should be in resulting file
	 */
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
	
	/**
	 * get position of sensor name in data array
	 * @param parameterName
	 * @return
	 */
	public int getParameterNameIndex(String parameterName) {
		return Util.StringArrayToMap(parameterNames).get(parameterName);
		
	}
	
	/**
	 * get one data column
	 * @param parameterName
	 * @return
	 */
	public float[] getValues(String parameterName) {
		return data[getParameterNameIndex(parameterName)];
	}
	
	/**
	 * returns time series with time interval exactly from clipStart to clipEnd
	 * @param clipStart	may be null if no clipping is needed
	 * @param clipEnd	may be null if no clipping is needed
	 * @return
	 */
	public TimeSeries getClipped(Long clipStart, Long clipEnd) {
		long clipStartTimestamp = clipStart==null?this.startTimestamp:clipStart;
		long clipEndTimestamp = clipEnd==null?this.startTimestamp+((this.data[0].length-1)*this.timeStep):clipEnd;	
		
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
		return new TimeSeries(this.parameterNames, clipStartTimestamp, timeStep, resultData);
	}
	
	/**
	 * get timestamp of first data entry
	 * @return
	 */
	public long getFirstTimestamp() {
		return startTimestamp;
	}
	
	/**
	 * get timestamp of last data entry
	 * @return
	 */
	public long getLastTimestamp() {
		return startTimestamp+((data[0].length-1)*timeStep);
	}
	
	public TimeSeriesIterator getIterator() {
		return new InternalIterator();
	}
	
	private class InternalIterator extends TimeSeriesIterator {
		
		private int pos;

		public InternalIterator() {
			super(new TimeSeriesSchema(parameterNames,timeStep));
			pos=0;
		}

		@Override
		public boolean hasNext() {
			return pos<data[0].length;
		}

		@Override
		public TimestampSeriesEntry next() {
			float[] resultData = new float[parameterNames.length];
			for(int columnIndex=0;columnIndex<parameterNames.length;columnIndex++) {
				resultData[columnIndex] = data[columnIndex][pos];
			}
			long timestamp = startTimestamp+(pos*timeStep);
			pos++;
			return new TimestampSeriesEntry(timestamp,resultData);
		}
		
	}

}
