package timeseriesdatabase.raw;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import org.apache.commons.lang3.StringUtils;
import org.apache.logging.log4j.Logger;




import de.umr.jepc.store.Event;
import timeseriesdatabase.TimeConverter;

import util.Util;

public class CSVTimeSeries {

	private static final Logger log = Util.log;

	public final Path filename;

	private Iterator<String> iterator_lines;

	public String serialnumber;
	public String[] parameterNames;

	public long timestampStart = 0;
	public long timestampEnd = 0;

	public CSVTimeSeries(Path filename) throws IOException {
		this.filename = filename;
		BufferedReader bufferedReader = Files.newBufferedReader(filename,Charset.defaultCharset());
		Stream<String> lines = bufferedReader.lines();
		iterator_lines = lines.iterator();
		readHeader();
	}

	private void readHeader() {	

		final int HEADER_LINE_COUNT = 5;
		String[] header = new String[HEADER_LINE_COUNT];
		int c=0;
		while(c<HEADER_LINE_COUNT && iterator_lines.hasNext()) {
			header[c] = iterator_lines.next();
			c++;
		}
		if(c<HEADER_LINE_COUNT) {
			throw new RuntimeException("read header error c<HEADER_LINE_COUNT");
		}
		final String HEADER_DESCRIPTION_NAME = "Description:";
		if(!header[0].startsWith(HEADER_DESCRIPTION_NAME)) {
			throw new RuntimeException("read header error !header[0].startsWith(HEADER_DESCRIPTION_NAME)");
		}
		String descriptionName = header[0].substring(HEADER_DESCRIPTION_NAME.length()).trim();
		//System.out.println(descriptionName);

		final String HEADER_SERIALNUMBER_NAME = "Serialnumber :";
		if(!header[1].startsWith(HEADER_SERIALNUMBER_NAME)) {
			throw new RuntimeException("read header error !header[1].startsWith(HEADER_SERIALNUMBER_NAME)");
		}
		serialnumber = ""+Long.parseLong(header[1].substring(HEADER_SERIALNUMBER_NAME.length()).trim());		
		//System.out.println(serialnumber);

		if(!header[2].startsWith("Logging Method:")) {
			throw new RuntimeException("read header error !header[2].startsWith('Logging Method:')");
		}
		//System.out.println(header[2]);
		if(!header[3].startsWith("MeasureInterval:")) {
			throw new RuntimeException("read header error !header[3].startsWith('MeasureInterval:'");
		}

		//Date	Time	Temperature   [°C]	Rel.Humidity   [%]	
		//String[] columnHeaders = StringUtils.split(header[4]);
		String[] columnHeaders = StringUtils.split(header[4], '\t');
		//util.Util.printArray(columnHeaders,"#");



		/*if(columnHeaders.length<2||columnHeaders.length%2!=0) {
			throw new RuntimeException("read header error columnHeaders.length<2||columnHeaders.length%2!=0:\t\t\t"+columnHeaders.length);
		}*/
		ArrayList<String> columnNamesList = new ArrayList<String>((columnHeaders.length/2)+1);
		for(String col:columnHeaders) {
			//System.out.println(col);
		}
		if(!columnHeaders[0].equals("Date")) {
			throw new RuntimeException("read header error !columnHeaders[0].equals('Date')");
		}
		columnNamesList.add("Date");
		if(!columnHeaders[1].equals("Time")) {
			throw new RuntimeException("read header error !columnHeaders[1].equals('Time')");
		}
		columnNamesList.add("Time");
		for(int i=2;i<columnHeaders.length;i++) {
			String name = columnHeaders[i].substring(0, columnHeaders[i].indexOf("[")).trim();
			//System.out.println("name: "+name);
			columnNamesList.add(name);
		}		
		String[] columnNames = columnNamesList.toArray(new String[0]);

		parameterNames = new String[columnNames.length-2];
		for(int i=0;i<parameterNames.length;i++) {
			parameterNames[i] = columnNames[i+2];
		}		
	}

	private static long parseTimestamp(String dateText, String timeText) {
		// 01.07.13
		int dayOfMonth = 10*(dateText.charAt(0)-'0')+(dateText.charAt(1)-'0');
		int month = 10*(dateText.charAt(3)-'0')+(dateText.charAt(4)-'0');
		int year = 2000 + 10*(dateText.charAt(6)-'0')+(dateText.charAt(7)-'0');

		// 09:30:00
		int hour = 10*(timeText.charAt(0)-'0')+(timeText.charAt(1)-'0');
		int minute = 10*(timeText.charAt(3)-'0')+(timeText.charAt(4)-'0');
		int second = 10*(timeText.charAt(6)-'0')+(timeText.charAt(7)-'0');

		LocalDateTime datetime = LocalDateTime.of(year, month, dayOfMonth, hour, minute, second);
		return TimeConverter.DateTimeToOleMinutes(datetime);
	}

	public TimestampSeries readEntries() {		
		List<TimeSeriesEntry> resultList = new ArrayList<TimeSeriesEntry>();

		timestampStart = -1;
		timestampEnd = -1;
		long timestampPrev = -1;
		int timeStep = -1;
		long timestamp = -1;

		boolean atStart = true;
		while(iterator_lines.hasNext()) {
			String line = iterator_lines.next();


			if(atStart) {
				if(line.startsWith("RUN")||line.startsWith("-------------")||line.startsWith("Messintervall")) {// one more pre data line
					continue;
				}
			}

			atStart= false;

			String[] row = StringUtils.split(line);
			if(row.length!=parameterNames.length+2) {
				throw new RuntimeException("read row error: "+line+"\t\t"+filename);
			}


			timestamp = parseTimestamp(row[0], row[1]);

			if(timestampStart==-1) {
				timestampStart = timestamp;
			}
			if(timestampPrev!=-1&&timeStep!=-1&&timestamp!=timestampPrev+timeStep) {
				throw new RuntimeException("kili CSV time step error");
			}
			if(timeStep!=-1&&timeStep!=(timestamp-timestampPrev)) {
				throw new RuntimeException("kili CSV time step error");
			}
			if(timeStep==-1&&timestampPrev!=-1) {
				timeStep = (int) (timestamp-timestampPrev);
				if(timeStep<1) {
					throw new RuntimeException("kili CSV time step error: time step needs to be at least one minute   in  "+filename);
				}
			}
			if(timestampPrev!=-1 && timestamp<=timestampPrev) {
				throw new RuntimeException("kili CSV timestamp error: prev: "+timestampPrev+" current: "+timestamp+" prev: "+TimeConverter.oleMinutesToText(timestampPrev)+" current: "+TimeConverter.oleMinutesToText(timestamp)+"     line: "+line);
			}
			

			float[] data = new float[parameterNames.length];
			for(int colIndex=0;colIndex<parameterNames.length;colIndex++) {
				try {
					float value = Float.parseFloat(row[colIndex+2]);
					data[colIndex] = value;
				} catch (NumberFormatException e) {
					e.printStackTrace();
					data[colIndex] = Float.NaN;
				}
			}

			resultList.add(new TimeSeriesEntry(timestamp,data));
			timestampPrev = timestamp;
		}
		timestampEnd = timestamp;		
		return new TimestampSeries(parameterNames,resultList,timeStep);		

	}

	public List<Event> toEvents(TimestampSeries timestampSeries, String[] translatedInputSchema, String[] targetSchema, String debugInfo) {

		//sourcePos[targetIndex] => sourceIndex
		int[] sourcePos = new int[targetSchema.length];
		for(int i=0;i<sourcePos.length;i++) {
			sourcePos[i] = -1;
		}
		boolean containsValidColumns = false;
		Map<String, Integer> targetIndexMap = Util.stringArrayToMap(targetSchema);
		for(int sourceIndex=0;sourceIndex<translatedInputSchema.length;sourceIndex++) {
			String sensorName = translatedInputSchema[sourceIndex];
			if(sensorName!=null) {
				if(targetIndexMap.containsKey(sensorName)) {
					sourcePos[targetIndexMap.get(sensorName)] = sourceIndex;
					containsValidColumns = true;
				} else {
					log.warn("sensor name not in target schema "+sensorName+" with "+debugInfo+" in "+serialnumber+"   "+filename+"   "+TimeConverter.oleMinutesToText(timestampStart)+" - "+TimeConverter.oleMinutesToText(timestampEnd));
				}
			} else {
				log.warn("no sensor translation: "+parameterNames[sourceIndex]+" with "+debugInfo+" in "+serialnumber+"   "+filename+"   "+TimeConverter.oleMinutesToText(timestampStart)+" - "+TimeConverter.oleMinutesToText(timestampEnd));
			}

		}

		if(containsValidColumns) {

			List<Event> eventList = new ArrayList<Event>(timestampSeries.entryList.size());

			for(TimeSeriesEntry entry:timestampSeries.entryList) {
				Float[] eventData = new Float[targetSchema.length];
				for(int schemaIndex=0;schemaIndex<targetSchema.length;schemaIndex++) {
					int sourceIndex = sourcePos[schemaIndex];
					if(sourceIndex==-1) {
						eventData[schemaIndex] = Float.NaN;
					} else {
						eventData[schemaIndex] = entry.data[sourceIndex];
					}
				}
				eventList.add(new Event(eventData, entry.timestamp));
			}	

			return eventList;
		} else {
			return null;
		}


	}

}
