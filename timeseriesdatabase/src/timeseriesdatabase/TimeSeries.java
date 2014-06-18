package timeseriesdatabase;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.apache.logging.log4j.Logger;

public class TimeSeries {
	
	private static final Logger log = Util.log;
	
	String[] parameterNames;	
	List<TimeSeriesEntry> entryList;
	
	TimeSeries(String[] parameterNames, List<TimeSeriesEntry> entryList) {
		this.parameterNames = parameterNames;
		this.entryList = entryList;
	}
	
	@Override
	public String toString() {
		int n = parameterNames.length>=10?10:parameterNames.length;
		String s="";
		s+="("+entryList.size()+")\t\t";
		for(int i=0;i<parameterNames.length;i++) {
			s+=parameterNames[i]+"\t";
		}
		s+='\n';
		for(int i=entryList.size()-n;i<entryList.size();i++) {			
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
	
	enum CSVTimeType {TIMESTAMP,DATETIME,NONE,TIMESTAMP_AND_DATETIME};
	
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
			for(TimeSeriesEntry entry:entryList) {
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
						//s+=Util.floatToString(entry.data[i]);
						printStream.format(Locale.ENGLISH," %3.3f", entry.data[i]);
					}
				}
				printStream.println();
			}
			printStream.close();
		} catch (FileNotFoundException e) {
			log.error(e);
		}
	}
	
	public TimeSeries getTimeInterval(long start, long end) {
		List<TimeSeriesEntry> resultList = new ArrayList<TimeSeriesEntry>();
		for(TimeSeriesEntry entry:entryList) {
			long timestamp = entry.timestamp;
			if( start<=timestamp && timestamp<=end ) {
				resultList.add(entry);
			}
		}
		return new TimeSeries(parameterNames,resultList);
	}

}
