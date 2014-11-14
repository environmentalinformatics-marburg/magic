package tsdb.raw;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TimeConverter;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesEntryIterator;
import tsdb.util.iterator.TsIterable;
import tsdb.util.iterator.TsIterator;

/**
 * time series with individual time stamp for each entry
 * @author woellauer
 *
 */
public class TimestampSeries implements TsIterable, Serializable {
	
	private static final Logger log = LogManager.getLogger();
	
	private static final long serialVersionUID = 6078067255995220349L;
	
	public static final TimestampSeries EMPTY_TIMESERIES = new TimestampSeries(new String[0],new ArrayList<TsEntry>(0),null);
	
	public String[] sensorNames;	
	public List<TsEntry> entryList;
	public Integer timeinterval; // null if raw data
	public String name;
	
	
	public TimestampSeries(String[] sensorNames, List<TsEntry> entryList,Integer timeinterval) {
		this.sensorNames = sensorNames;
		this.entryList = entryList;
		this.timeinterval = timeinterval;
		this.name = null;
	}
	
	public TimestampSeries(String name, String[] sensorNames, List<TsEntry> entryList) {
		this.sensorNames = sensorNames;
		this.entryList = entryList;
		this.timeinterval = null;
		this.name = name;
	}
	
	public static TimestampSeries create(TsIterator input_iterator) {
		if(!input_iterator.hasNext()) {
			log.warn("TimestampSeries.create: input_iterator is empty");
			//new Exception().printStackTrace(System.out);
			return null;
		}
		List<TsEntry> entryList = new ArrayList<TsEntry>();
		while(input_iterator.hasNext()) {
			TsEntry next = input_iterator.next();
			entryList.add(next);
		}
		return new TimestampSeries(input_iterator.getNames(), entryList, null);
	}
	
	@Override
	public String toString() {
		int n = entryList.size()>=10?10:entryList.size();
		String s="";
		s+="("+entryList.size()+")\t\t";
		for(int i=0;i<sensorNames.length;i++) {
			s+=sensorNames[i]+"\t";
		}
		s+='\n';
		for(int i=0;i<n;i++) {			
			TsEntry entry = entryList.get(i);
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
		int[] columnEntryCounter = new int[sensorNames.length];
		for(int i=0;i<sensorNames.length;i++) {
			columnEntryCounter[i] = 0;
		}
		for(TsEntry entry:entryList) {
			for(int i=0;i<sensorNames.length;i++) {
				if(!Float.isNaN(entry.data[i])) {
					columnEntryCounter[i]++;
				}
			}
		}
		List<Integer> removColumnsList = new ArrayList<Integer>();
		for(int i=0;i<sensorNames.length;i++) {
			if(columnEntryCounter[i] == 0) {
				removColumnsList.add(i);
			}
		}
		if(removColumnsList.size()==0) {
			return; //not columns to remove;
		}
		int newSize = sensorNames.length-removColumnsList.size();
		int[] newPos = new int[newSize];
		int currPos = 0;
		for(int i=0;i<sensorNames.length;i++) {			
			if(columnEntryCounter[i] != 0) {
				newPos[currPos] = i;
				currPos++;
			}
		}
		String[] newParameterNames = new String[newSize];
		for(int i=0;i<newSize;i++) {
			newParameterNames[i] = sensorNames[newPos[i]];
		}
		List<TsEntry> newEntryList = new ArrayList<TsEntry>(entryList.size());
		for(TsEntry entry:entryList) {
			float[] newData = new float[newSize];
			for(int i=0;i<newSize;i++) {
				newData[i] = entry.data[newPos[i]];
			}
			newEntryList.add(new TsEntry(entry.timestamp,newData));
		}
		sensorNames = newParameterNames;
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
		List<TsEntry> resultList = new ArrayList<TsEntry>();
		for(TsEntry entry:entryList) {
			long timestamp = entry.timestamp;
			if( start<=timestamp && timestamp<=end ) {
				resultList.add(entry);
			}
		}
		return new TimestampSeries(sensorNames,resultList,timeinterval);
	}
	
	public List<Long> getNaNList(String parameterName) {
		
		int columnID = Util.stringArrayToMap(sensorNames).get(parameterName);

		List<Long> gapList = new ArrayList<Long>();
		long currentTimeStamp = -1;
		for(TsEntry entry:entryList) {
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
	
	public int size() {
		return entryList.size();
	}

	@Override
	public TsIterator tsIterator() {
		return new TimeSeriesEntryIterator(entryList.iterator(),sensorNames);
	}

}
