package tsdb.raw;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;

import tsdb.TimeConverter;
import tsdb.util.Util;
import tsdb.util.iterator.SchemaIterator;
import tsdb.util.iterator.TimeSeriesEntryIterator;
import tsdb.util.iterator.TimeSeriesIterable;
import tsdb.util.iterator.TimeSeriesIterator;

/**
 * time series with individual time stamp for each entry
 * @author woellauer
 *
 */
public class TimestampSeries implements TimeSeriesIterable, Serializable {
	
	private static final long serialVersionUID = 6078067255995220349L;

	private static final Logger log = Util.log;
	
	public static final TimestampSeries EMPTY_TIMESERIES = new TimestampSeries(new String[0],new ArrayList<TimeSeriesEntry>(0),null);
	
	public String[] parameterNames;	
	public List<TimeSeriesEntry> entryList;
	public Integer timeinterval; // null if raw data
	
	
	public TimestampSeries(String[] parameterNames, List<TimeSeriesEntry> entryList,Integer timeinterval) {
		this.parameterNames = parameterNames;
		this.entryList = entryList;
		this.timeinterval = timeinterval;
	}
	
	public static TimestampSeries create(SchemaIterator<TimeSeriesEntry> input_iterator) {
		if(!input_iterator.hasNext()) {
			log.warn("TimestampSeries.create: input_iterator is empty");
			//new Exception().printStackTrace(System.out);
			return null;
		}
		List<TimeSeriesEntry> entryList = new ArrayList<TimeSeriesEntry>();
		while(input_iterator.hasNext()) {
			TimeSeriesEntry next = input_iterator.next();
			entryList.add(next);
		}
		return new TimestampSeries(input_iterator.getOutputSchema(), entryList, null);
	}
	
	@Override
	public String toString() {
		int n = entryList.size()>=10?10:entryList.size();
		String s="";
		s+="("+entryList.size()+")\t\t";
		for(int i=0;i<parameterNames.length;i++) {
			s+=parameterNames[i]+"\t";
		}
		s+='\n';
		for(int i=0;i<n;i++) {			
			TimeSeriesEntry entry = entryList.get(i);
			float[] data = entry.data;
			s+="["+entry.timestamp+"   "+TimeConverter.oleMinutesToLocalDateTime(entry.timestamp)+"]\t";
			for(int c=0;c<data.length;c++) {
				s+=Util.floatToString(data[c])+"\t";
			}
			s+='\n';
		}
		
		return s;
	}
	
	public void removeEmptyColumns() {
		int[] columnEntryCounter = new int[parameterNames.length];
		for(int i=0;i<parameterNames.length;i++) {
			columnEntryCounter[i] = 0;
		}
		for(TimeSeriesEntry entry:entryList) {
			for(int i=0;i<parameterNames.length;i++) {
				if(!Float.isNaN(entry.data[i])) {
					columnEntryCounter[i]++;
				}
			}
		}
		List<Integer> removColumnsList = new ArrayList<Integer>();
		for(int i=0;i<parameterNames.length;i++) {
			if(columnEntryCounter[i] == 0) {
				removColumnsList.add(i);
			}
		}
		if(removColumnsList.size()==0) {
			return; //not columns to remove;
		}
		int newSize = parameterNames.length-removColumnsList.size();
		int[] newPos = new int[newSize];
		int currPos = 0;
		for(int i=0;i<parameterNames.length;i++) {			
			if(columnEntryCounter[i] != 0) {
				newPos[currPos] = i;
				currPos++;
			}
		}
		String[] newParameterNames = new String[newSize];
		for(int i=0;i<newSize;i++) {
			newParameterNames[i] = parameterNames[newPos[i]];
		}
		List<TimeSeriesEntry> newEntryList = new ArrayList<TimeSeriesEntry>(entryList.size());
		for(TimeSeriesEntry entry:entryList) {
			float[] newData = new float[newSize];
			for(int i=0;i<newSize;i++) {
				newData[i] = entry.data[newPos[i]];
			}
			newEntryList.add(new TimeSeriesEntry(entry.timestamp,newData));
		}
		parameterNames = newParameterNames;
		entryList = newEntryList;
	}
	
	/*public void writeToCSV(String filename, String separator, String nanText, CSVTimeType csvTimeType) {
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
			for(TimestampSeriesEntry entry:entryList) {
				if(time) {
					switch(csvTimeType) {
					case TIMESTAMP:
						printStream.print(entry.timestamp);
						break;
					case DATETIME:
						printStream.print(TimeConverter.oleMinutesToLocalDateTime(entry.timestamp));
						break;
					case TIMESTAMP_AND_DATETIME:
						printStream.print(entry.timestamp);
						printStream.print(separator);
						printStream.print(TimeConverter.oleMinutesToLocalDateTime(entry.timestamp));
						break;
					default:
						printStream.print("---");
					}
				}
				float[] data = entry.data;
				for(int i=0;i<entry.data.length;i++) {
					if(time||i>0) {
						printStream.print(separator);
					}
					if(Float.isNaN(data[i])) {
						printStream.print(nanText);
					} else {
						printStream.format(Locale.ENGLISH,"%3.3f", entry.data[i]);
					}
				}
				printStream.println();
			}
			printStream.close();
		} catch (FileNotFoundException e) {
			log.error(e);
		}
	}*/
	
	public TimestampSeries getTimeInterval(long start, long end) {
		List<TimeSeriesEntry> resultList = new ArrayList<TimeSeriesEntry>();
		for(TimeSeriesEntry entry:entryList) {
			long timestamp = entry.timestamp;
			if( start<=timestamp && timestamp<=end ) {
				resultList.add(entry);
			}
		}
		return new TimestampSeries(parameterNames,resultList,timeinterval);
	}
	
	public List<Long> getNaNList(String parameterName) {
		
		int columnID = Util.stringArrayToMap(parameterNames).get(parameterName);

		List<Long> gapList = new ArrayList<Long>();
		long currentTimeStamp = -1;
		for(TimeSeriesEntry entry:entryList) {
			if(!Float.isNaN(entry.data[columnID])) {
				long nextTimeStamp = entry.timestamp;
				if(currentTimeStamp>-1&&currentTimeStamp+timeinterval<nextTimeStamp) {
					System.out.println("gap: "+(nextTimeStamp-(currentTimeStamp+timeinterval)));
					gapList.add(nextTimeStamp);
				}
				currentTimeStamp = nextTimeStamp;
			}
		}
		return gapList;
	}	
	
	public long getFirstTimestamp() {
		return this.entryList.get(0).timestamp;
	}
	
	public long getLastTimestamp() {
		return this.entryList.get(entryList.size()-1).timestamp;
	}

	@Override
	public TimeSeriesIterator timeSeriesIterator() {
		return new TimeSeriesEntryIterator(entryList.iterator(),parameterNames);
	}

}
