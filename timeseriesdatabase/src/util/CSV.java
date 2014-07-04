package util;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.Locale;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.iterator.TimeSeriesIterable;
import util.iterator.TimeSeriesIterator;

public class CSV {
	
	private static final Logger log = Util.log;	
	
	public static void write(TimeSeriesIterable input, String filename, String separator, String nanText, CSVTimeType csvTimeType) {
		write(input.timeSeriesIterator(), filename, separator, nanText, csvTimeType);
	}
	
	public static void write(TimeSeriesIterator it, String filename, String separator, String nanText, CSVTimeType csvTimeType) {
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
			
			String[] sensorNames = it.getOutputSchema();
			
			for(int i=0;i<sensorNames.length;i++) {
				if(time||i>0) {
					printStream.print(separator);
				}
				printStream.print(sensorNames[i]);				
			}
			printStream.println();
			
			while(it.hasNext()) {
				
				TimeSeriesEntry entry = it.next();	
				long timestamp = entry.timestamp;
				float[] data = entry.data;
				
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
					float value = data[columnIndex];
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
	
	
	

}
