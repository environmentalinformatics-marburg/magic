package timeseriesdatabase.aggregated;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.CSVTimeType;
import util.ProcessingChainEntry;
import util.ProcessingChainTitle;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterable;
import util.iterator.TimeSeriesIterator;

/**
 * time series of aggregated data. time interval between values is constant
 * @author woellauer
 *
 */
public class TimeSeries implements TimeSeriesIterable {

	private static final Logger log = Util.log;

	//used for metadata, may be null
	private final List<ProcessingChainEntry> processingChain;

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

	public boolean hasDataQualityFlag;
	public boolean hasDataInterpolatedFlag;

	public DataQuality[][] dataQuality;
	public boolean[][] dataInterpolated;

	public TimeSeries(List<ProcessingChainEntry> processingChain, String[] parameterNames, long startTimestamp, int timeStep, float[][] data, DataQuality[][] dataQuality, boolean[][] dataInterpolated) {
		this.processingChain = Util.createList(processingChain,new ProcessingChainTitle("TimeSeries"));
		this.parameterNames = parameterNames;
		this.startTimestamp = startTimestamp;
		this.timeStep = timeStep;
		this.data = data;
		this.dataQuality = dataQuality;
		this.dataInterpolated = dataInterpolated;
		this.hasDataQualityFlag = false;
		this.hasDataInterpolatedFlag = false;
	}

	/**
	 * Converts elements of an iterator in TimeSeries object.
	 * Elements need to be in ordered in timeStep time intervals
	 * @param input_iterator
	 * @param timeStep
	 * @return
	 */
	public static TimeSeries create(TimeSeriesIterator input_iterator) {
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

		ArrayList<TimeSeriesEntry> entryList = Util.iteratorToList(input_iterator);		
		long startTimestamp = entryList.get(0).timestamp;
		float[][] data = new float[schema.length][entryList.size()];
		DataQuality[][] dataQuality = new DataQuality[schema.length][entryList.size()];
		boolean[][] dataInterpolated = new boolean[schema.length][entryList.size()];

		long timestamp=-1;
		for(int i=0;i<entryList.size();i++) {
			TimeSeriesEntry entry = entryList.get(i);
			if(timestamp==-1||timestamp+timeSeriesSchema.timeStep==entry.timestamp) {
				for(int column=0;column<schema.length;column++) {
					data[column][i] = entry.data[column];
				}
			} else {
				log.error("timestamps are not in timestep intervals");
				return null;
			}
			timestamp = entry.timestamp;
			if(entry.qualityFlag!=null) {
				for(int column=0;column<schema.length;column++) {
					dataQuality[column][i] = entry.qualityFlag[column];
				}
			} else {
				for(int column=0;column<schema.length;column++) {
					dataQuality[column][i] = DataQuality.Na;
				}				
			}
		}

		TimeSeries result = new TimeSeries(input_iterator.getProcessingChain(),schema, startTimestamp, timeSeriesSchema.timeStep, data, dataQuality, dataInterpolated);

		result.hasDataQualityFlag = input_iterator.getOutputTimeSeriesSchema().hasQualityFlags;
		result.hasDataInterpolatedFlag = false; //TODO

		return result;

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

		Iterator<TimeSeriesEntry> it = timestampSeries.entryList.iterator();
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

		return new TimeSeries(null,timestampSeries.parameterNames, startTimestamp, timeStep, resultData, null, null);
	}

	/**
	 * some summary data of this time series
	 */
	public String toString() {
		return "BaseTimeSeries: "+startTimestamp+"\t"+timeStep+"\t"+data.length+"\t"+data[0].length;
	}

	/**
	 * get position of sensor name in data array
	 * @param parameterName
	 * @return
	 */
	public int getParameterNameIndex(String parameterName) {
		return Util.stringArrayToMap(parameterNames).get(parameterName);

	}
	
	public boolean containsParamterName(String parameterName) {
		return Util.stringArrayToMap(parameterNames).containsKey(parameterName);
	}

	/**
	 * get one data column
	 * @param parameterName
	 * @return
	 */
	public float[] getValues(String parameterName) {
		return data[getParameterNameIndex(parameterName)];
	}

	public boolean[] getInterpolationFlags(String parameterName) {
		System.out.println("parameterName "+parameterName);
		return dataInterpolated[getParameterNameIndex(parameterName)];
	}


	/**
	 * returns time series with time interval exactly from clipStart to clipEnd
	 * @param clipStart	may be null if no clipping is needed
	 * @param clipEnd	may be null if no clipping is needed
	 * @return
	 */
	/*@Deprecated	
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
		DataQuality[][] resultQuality = new DataQuality[parameterNames.length][(int) (((clipEndTimestamp-clipStartTimestamp)/timeStep)+1)];
		boolean[][] resultInterpolated = new boolean[parameterNames.length][(int) (((clipEndTimestamp-clipStartTimestamp)/timeStep)+1)];
		for(long timestamp=clipStartTimestamp;timestamp<=clipEndTimestamp;timestamp+=timeStep) {
			if(timestamp<startTimestamp || timestamp>startTimestamp+(this.data[0].length*timeStep)) {
				for(int i=0; i<parameterNames.length; i++) {
					resultData[i][(int) ((timestamp-clipStartTimestamp)/timeStep)] = Float.NaN;
					resultQuality[i][(int) ((timestamp-clipStartTimestamp)/timeStep)] = DataQuality.Na;
					// resultInterpolated[..][..]  == false
				}
			} else {
				for(int i=0; i<parameterNames.length; i++) {
					resultData[i][(int) ((timestamp-clipStartTimestamp)/timeStep)] = this.data[i][(int) ((timestamp-startTimestamp)/timeStep)];
					resultQuality[i][(int) ((timestamp-clipStartTimestamp)/timeStep)] = this.dataQuality[i][(int) ((timestamp-startTimestamp)/timeStep)];
					resultInterpolated[i][(int) ((timestamp-clipStartTimestamp)/timeStep)] = this.dataInterpolated[i][(int) ((timestamp-startTimestamp)/timeStep)];
				}
			}
		}

		return new TimeSeries(Util.createList(processingChain,new ProcessingChainTitle("clip")),this.parameterNames, clipStartTimestamp, timeStep, resultData, resultQuality, resultInterpolated);
	}*/

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

	@Override
	public TimeSeriesIterator timeSeriesIterator() {
		return new InternalClipIterator(null, null);
	}
	
	public TimeSeriesIterator timeSeriesIteratorCLIP(Long clipStart, Long clipEnd) {
		return new InternalClipIterator(clipStart, clipEnd);
	}

	public TimeSeriesSchema createSchema() {
		String[] schema = parameterNames;
		boolean constantTimeStep = true;
		boolean isContinuous = true;		
		boolean hasQualityFlags = hasDataQualityFlag; //TODO
		boolean hasInterpolatedFlags = hasDataInterpolatedFlag; //TODO
		boolean hasQualityCounters = false; //TODO
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;

	}

	/*
	@Deprecated
	private class InternalIterator extends TimeSeriesIterator {

		private int pos;		

		public InternalIterator() {
			super(createSchema());
			pos=0;
		}

		@Override
		public boolean hasNext() {
			return pos<data[0].length;
		}

		@Override
		public TimeSeriesEntry next() {
			float[] resultData = new float[parameterNames.length];
			DataQuality[] resultQuality = new DataQuality[parameterNames.length];
			boolean[] resultInterpolated = new boolean[parameterNames.length];
			for(int columnIndex=0;columnIndex<parameterNames.length;columnIndex++) {
				resultData[columnIndex] = data[columnIndex][pos];
				resultQuality[columnIndex] = dataQuality[columnIndex][pos];
				resultInterpolated[columnIndex] = dataInterpolated[columnIndex][pos];
			}
			long timestamp = startTimestamp+(pos*timeStep);
			pos++;
			return new TimeSeriesEntry(timestamp,resultData,resultQuality,null,resultInterpolated);
		}

		@Override
		public String getIteratorName() {
			return "TimeSeries.InternalIterator";
		}

		@Override
		public List<ProcessingChainEntry> getProcessingChain() {
			List<ProcessingChainEntry> result = null;
			if(processingChain==null) {
				result = new ArrayList<ProcessingChainEntry>();
			} else {
				result = processingChain;	
			}
			result.add(this);
			return result;
		}		
	}*/


	private class InternalClipIterator extends TimeSeriesIterator {

		private int pos;
		private final int endPos;

		public InternalClipIterator(Long clipStart, Long clipEnd) {
			super(createSchema());

			long clipStartTimestamp = clipStart==null?getFirstTimestamp():clipStart;
			long clipEndTimestamp = clipEnd==null?getLastTimestamp():clipEnd;	

			if(clipStartTimestamp>clipEndTimestamp) {
				throw new RuntimeException("wrong data");
			}
			if(clipStartTimestamp%timeStep!=0||clipEndTimestamp%timeStep!=0) {
				throw new RuntimeException("timeststamps not alligned");
			}

			pos = (int) ((clipStartTimestamp-getFirstTimestamp())/timeStep);
			endPos = (int) ((clipEndTimestamp-getFirstTimestamp())/timeStep);
		}

		@Override
		public boolean hasNext() {			
			return pos<=endPos;
		}

		@Override
		public TimeSeriesEntry next() {
			if(hasNext()) {
				if(pos>=0 && pos<data[0].length) {					
					float[] resultData = new float[parameterNames.length];
					DataQuality[] resultQuality = new DataQuality[parameterNames.length];
					boolean[] resultInterpolated = new boolean[parameterNames.length];
					for(int columnIndex=0;columnIndex<parameterNames.length;columnIndex++) {
						resultData[columnIndex] = data[columnIndex][pos];
						resultQuality[columnIndex] = dataQuality[columnIndex][pos];
						resultInterpolated[columnIndex] = dataInterpolated[columnIndex][pos];
					}
					long timestamp = startTimestamp+(pos*timeStep);
					pos++;
					return new TimeSeriesEntry(timestamp,resultData,resultQuality,null,resultInterpolated);					
				} else {
					long timestamp = startTimestamp+(pos*timeStep);
					pos++;
					return TimeSeriesEntry.createNaN(timestamp, parameterNames.length);
				}
			} else {
				throw new RuntimeException("iterator out of range");
			}
		}

		@Override
		public List<ProcessingChainEntry> getProcessingChain() {
			List<ProcessingChainEntry> result = null;
			if(processingChain==null) {
				result = new ArrayList<ProcessingChainEntry>();
			} else {
				result = processingChain;	
			}
			result.add(this);
			return result;
		}	

		@Override
		public String getIteratorName() {
			return "InternalClipIterator";
		}
	}
}
