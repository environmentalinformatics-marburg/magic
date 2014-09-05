package tsdb.util;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.Locale;

import org.apache.logging.log4j.Logger;

import tsdb.TimeConverter;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.iterator.TimeSeriesIterable;
import tsdb.util.iterator.TimeSeriesIterator;

/**
 * Writes time series data to CSV file with some format options.
 * @author woellauer
 *
 */
public class CSV {

	private static final Logger log = Util.log;	

	public static void writeNoHeader(TimeSeriesIterator it, String filename, String separator, String nanText, CSVTimeType csvTimeType) {
		write(it, false, filename, separator, nanText, csvTimeType, false, false);
	}


	public static void write(TimeSeriesIterable input, String filename, String separator, String nanText, CSVTimeType csvTimeType) {
		write(input, filename, separator, nanText, csvTimeType, false);
	}
	
	public static void write(TimeSeriesIterable input, String filename) {
		write(input, filename, ",", "NA", CSVTimeType.TIMESTAMP_AND_DATETIME);
	}

	public static void write(TimeSeriesIterable input, String filename, String separator, String nanText, CSVTimeType csvTimeType, boolean qualityFlag) {
		write(input.timeSeriesIterator(), filename, separator, nanText, csvTimeType, qualityFlag, false);
	}
	
	public static void write(TimeSeriesIterator it, String filename) {
		write(it, filename, ",", "NA", CSVTimeType.TIMESTAMP_AND_DATETIME);
	}

	public static void write(TimeSeriesIterator it, String filename, String separator, String nanText, CSVTimeType csvTimeType) {
		write(it, filename, separator, nanText, csvTimeType, false, false);
	}

	public static void write(TimeSeriesIterator it, String filename, String separator, String nanText, CSVTimeType csvTimeType, boolean qualityFlag, boolean qualityCounter) {
		write(it, true, filename, separator, nanText, csvTimeType, qualityFlag, qualityCounter);
	}
	
	
		

	public static void write(TimeSeriesIterator it, boolean header, String filename, String separator, String nanText, CSVTimeType csvTimeType, boolean qualityFlag, boolean qualityCounter) {
		try {
			FileOutputStream out = new FileOutputStream(filename);
			write(it, header, out, separator, nanText, csvTimeType, qualityFlag, qualityCounter);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}
	public static void write(TimeSeriesIterator it, boolean header, OutputStream out, String separator, String nanText, CSVTimeType csvTimeType, boolean qualityFlag, boolean qualityCounter) {		
		boolean time=false;
		if(csvTimeType==CSVTimeType.TIMESTAMP||csvTimeType==CSVTimeType.DATETIME||csvTimeType==CSVTimeType.TIMESTAMP_AND_DATETIME) {
			time=true;
		}

			PrintStream printStream = new PrintStream(out);

			if(header) {

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

				if(qualityFlag) {
					printStream.print(separator);
					printStream.print("qualityflag");	
				}

				if(qualityCounter) {
					printStream.print(separator);
					printStream.print("qualityCounter");	
				}


				printStream.println();

			}

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

				if(qualityFlag) {
					printStream.print(separator);

					if(entry.qualityFlag==null) {
						printStream.print(nanText);
					} else {
						for(int qIndex=0; qIndex<entry.qualityFlag.length; qIndex++) {
							switch(entry.qualityFlag[qIndex]) {
							case Na:
								printStream.print('n');
								break;
							case NO:
								printStream.print(0);
								break;
							case PHYSICAL:
								printStream.print(1);
								break;
							case STEP:
								printStream.print(2);
								break;
							case EMPIRICAL:
								printStream.print(3);
								break;
							default:
								printStream.print('?');

							}
						}
					}



				}

				if(qualityCounter) {
					printStream.print(separator);
					if(entry.qualityCounter==null) {
						printStream.print(nanText);
					} else {
						int[][] counter = entry.qualityCounter;
						for(int c=0;c<counter.length;c++) {
							if(c>0) {
								printStream.print('-');
							}
							for(int q=0;q<counter[c].length;q++) {
								if(q>0) {
									printStream.print('_');
								}
								printStream.print(counter[c][q]);
							}
						}

					}


				}

				printStream.println();
			}
			//printStream.close();

	}




}
