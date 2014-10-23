package tsdb.loader;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.TreeMap;
import java.util.stream.Stream;

import org.apache.commons.lang3.StringUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.raw.TsEntry;
import tsdb.raw.TimestampSeries;
import de.umr.jepc.store.Event;

public class KiLiCSV {
	
	private static final Logger log = LogManager.getLogger();
	
	public final String serial;
	public final TreeMap<Long, Event> eventMap;
	public final long timestampStart;
	public final long timestampEnd;

	public KiLiCSV(String serial, TreeMap<Long, Event> eventMap,long timestampStart,long timestampEnd) {
		this.serial = serial;
		this.eventMap = eventMap;
		this.timestampStart = timestampStart;
		this.timestampEnd = timestampEnd;
	}
	
	public static TimestampSeries readFile(Path path) throws IOException {

		BufferedReader bufferedReader = Files.newBufferedReader(path,Charset.defaultCharset());

		Stream<String> lines = bufferedReader.lines();

		Iterator<String> it = lines.iterator();

		final int HEADER_LINE_COUNT = 5;
		String[] header = new String[HEADER_LINE_COUNT];
		int c=0;
		while(c<HEADER_LINE_COUNT && it.hasNext()) {
			header[c] = it.next();
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
		String serialnumber = ""+Long.parseLong(header[1].substring(HEADER_SERIALNUMBER_NAME.length()).trim());		
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
		
		ArrayList<TsEntry> resultList = new ArrayList<TsEntry>();

		long timestampStart = 0;
		long timestampEnd = 0;
		int timeStep = 0;

		boolean atStart = true;
		while(it.hasNext()) {
			String line = it.next();

			if(atStart) {
				if(line.startsWith("RUN")||line.startsWith("-------------")||line.startsWith("Messintervall")) {// one more pre data line
					continue;
				}
			}

			atStart= false;

			String[] row = StringUtils.split(line);
			if(row.length!=columnNames.length) {
				//util.Util.printArray(columnNames,";");
				throw new RuntimeException("read row error: "+line+"\t\t"+header[4]+"\t\t"+columnNames.length+"\t\t"+path);
			}


			String dateText = row[0]; // 01.07.13
			int dayOfMonth = 10*(dateText.charAt(0)-'0')+(dateText.charAt(1)-'0');
			int month = 10*(dateText.charAt(3)-'0')+(dateText.charAt(4)-'0');
			int year = 2000 + 10*(dateText.charAt(6)-'0')+(dateText.charAt(7)-'0');

			String timeText = row[1]; // 09:30:00
			int hour = 10*(timeText.charAt(0)-'0')+(timeText.charAt(1)-'0');
			int minute = 10*(timeText.charAt(3)-'0')+(timeText.charAt(4)-'0');
			int second = 10*(timeText.charAt(6)-'0')+(timeText.charAt(7)-'0');

			LocalDateTime datetime = LocalDateTime.of(year, month, dayOfMonth, hour, minute, second);
			long timestamp = TimeConverter.DateTimeToOleMinutes(datetime);
			
			if(timestampStart==0) {
				timestampStart = timestamp;
			}
			if(timestamp<=timestampEnd) {
				throw new RuntimeException("kili CSV timestamp error");
			}
			if(timestampEnd!=0&&timeStep!=0&&timestamp!=timestampEnd+timeStep) {
				throw new RuntimeException("kili CSV time step error");
			}
			if(timeStep==0&&timestampEnd!=0) {
				timeStep = (int) (timestamp-timestampEnd);
			}
			timestampEnd = timestamp;
			
			float[] data = new float[columnNames.length-2];
			for(int colIndex=0;colIndex<columnNames.length-2;colIndex++) {
				try {
					float value = Float.parseFloat(row[colIndex-2]);
					data[colIndex] = value;
				} catch (NumberFormatException e) {
					e.printStackTrace();
					data[colIndex] = Float.NaN;
				}
			}
			
			resultList.add(new TsEntry(timestamp,data));
		}

		bufferedReader.close();
		
		String[] parameterNames = new String[columnNames.length-2];
		for(int i=0;i<parameterNames.length;i++) {
			parameterNames[i] = columnHeaders[i+2];
		}
		
		return new TimestampSeries(parameterNames,resultList,timeStep);		
	}



	public static KiLiCSV readFileOLD(TsDB timeSeriesDatabase, Path path) throws IOException {

		/*String filename = "filename.CSV";
		Object filereader = new FileInputStream(filename);

		FileSystemProvider f;*/

		/*String fileSystem = "file:/";
		String filePath = "C:/timeseriesdatabase_data_source_structure_kili/0000cof4/ra01_nai05_0000/";
		String filename = "ki_0000cof4_000rug_201307010925_201308090620_mez_ra01_nai05_0000.asc";*/
		//Path path = Paths.get(URI.create(fileSystem+filePath+filename));


		BufferedReader bufferedReader = Files.newBufferedReader(path,Charset.defaultCharset());

		Stream<String> lines = bufferedReader.lines();

		Iterator<String> it = lines.iterator();

		final int HEADER_LINE_COUNT = 5;
		String[] header = new String[HEADER_LINE_COUNT];
		int c=0;
		while(c<HEADER_LINE_COUNT && it.hasNext()) {
			header[c] = it.next();
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
		String serialnumber = ""+Long.parseLong(header[1].substring(HEADER_SERIALNUMBER_NAME.length()).trim());		
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
		
		//*********************schama mapping ***************************
		
		String[] schema  = timeSeriesDatabase.getStation(serialnumber).loggerType.sensorNames;
		//System.out.println(timeSeriesDatabase.getStation(serialnumber).getLoggerType().typeName);
		//System.out.println(":: "+Util.arrayToString(columnNames));
		//System.out.println("-> "+Util.arrayToString(schema));
		
		//mapping: UDBFTimeSeries column index position -> Event column index position;    eventPos[i] == -1 -> no mapping		
				int[] eventPos = new int[columnNames.length];  
				eventPos[0] = -1;
				eventPos[1] = -1;
				//creates mapping eventPos   (  udbf pos -> event pos )
				for(int sensorIndex=2; sensorIndex<columnNames.length; sensorIndex++) {
					eventPos[sensorIndex] = -1;
					String rawSensorName = columnNames[sensorIndex];
					if(!timeSeriesDatabase.containsIgnoreSensorName(rawSensorName)) {
						String sensorName = timeSeriesDatabase.getStation(serialnumber).translateInputSensorName(rawSensorName,false);
						//System.out.println(rawSensorName+" -> "+sensorName+"   "+timeSeriesDatabase.getStation(serialnumber).getLoggerType().sensorNameTranlationMap.get(rawSensorName)+"   "+timeSeriesDatabase.getStation(serialnumber).getLoggerType().sensorNameTranlationMap);
						//System.out.println(sensorHeader.name+"->"+sensorName);
						if(sensorName != null) {
							for(int schemaIndex=0;schemaIndex<schema.length;schemaIndex++) {
								String schemaSensorName = schema[schemaIndex];
								if(schemaSensorName.equals(sensorName)) {
									eventPos[sensorIndex] = schemaIndex;
								}
							}
						}
						if(eventPos[sensorIndex] == -1) {
							if(sensorName==null) {
								log.warn("sensor name not in translation map: "+rawSensorName+" -> "+sensorName);
							} else {
								log.trace("sensor name not in schema: "+rawSensorName+" -> "+sensorName);
							}
						}
					}
				}

				//mapping event index position -> sensor index position 
				int[] sensorPos = new int[schema.length];
				for(int i=0;i<sensorPos.length;i++) {
					sensorPos[i] = -1;
				}
				int validSensorCount = 0;
				for(int i=0;i<eventPos.length;i++) {
					if(eventPos[i]>-1) {
						validSensorCount++;
						sensorPos[eventPos[i]] = i;
					}
				}

				if(validSensorCount<1) {
					log.trace("no fitting sensors in "+path);
					return null; //all event columns are empty
				}
		
		
				//*********************end of schama mapping ***************************


		TreeMap<Long, Event> eventMap = new TreeMap<Long, Event>();
		long timestampStart = 0;
		long timestampEnd = 0;
		long timeStep = 0;

		boolean atStart = true;
		while(it.hasNext()) {
			String line = it.next();

			if(atStart) {
				if(line.startsWith("RUN")||line.startsWith("-------------")||line.startsWith("Messintervall")) {// one more pre data line
					continue;
				}
			}

			atStart= false;

			String[] row = StringUtils.split(line);
			if(row.length!=columnNames.length) {
				//util.Util.printArray(columnNames,";");
				throw new RuntimeException("read row error: "+line+"\t\t"+header[4]+"\t\t"+columnNames.length+"\t\t"+path);
			}


			String dateText = row[0]; // 01.07.13
			int dayOfMonth = 10*(dateText.charAt(0)-'0')+(dateText.charAt(1)-'0');
			int month = 10*(dateText.charAt(3)-'0')+(dateText.charAt(4)-'0');
			int year = 2000 + 10*(dateText.charAt(6)-'0')+(dateText.charAt(7)-'0');

			String timeText = row[1]; // 09:30:00
			int hour = 10*(timeText.charAt(0)-'0')+(timeText.charAt(1)-'0');
			int minute = 10*(timeText.charAt(3)-'0')+(timeText.charAt(4)-'0');
			int second = 10*(timeText.charAt(6)-'0')+(timeText.charAt(7)-'0');

			LocalDateTime datetime = LocalDateTime.of(year, month, dayOfMonth, hour, minute, second);
			long timestamp = TimeConverter.DateTimeToOleMinutes(datetime);
			
			if(timestampStart==0) {
				timestampStart = timestamp;
			}
			if(timestamp<=timestampEnd) {
				throw new RuntimeException("kili CSV timestamp error");
			}
			if(timestampEnd!=0&&timeStep!=0&&timestamp!=timestampEnd+timeStep) {
				throw new RuntimeException("kili CSV time step error");
			}
			if(timeStep==0&&timestampEnd!=0) {
				timeStep = timestamp-timestampEnd;
			}
			timestampEnd = timestamp;
			
			//System.out.println(datetime+" "+timestamp);

			/*Float[] data = new Float[columnNames.length-2];
			for(int colIndex=2;colIndex<columnNames.length;colIndex++) {
				try {
					float value = Float.parseFloat(row[colIndex]);
					data[colIndex-2] = value;
				} catch (NumberFormatException e) {
					e.printStackTrace();
					data[colIndex-2] = Float.NaN;
				}
				//System.out.println(value);
			}*/
			
			Float[] data = new Float[schema.length];
			for(int schemaIndex=0;schemaIndex<schema.length;schemaIndex++) {
				if(sensorPos[schemaIndex]>-1) {
					try {
						float value = Float.parseFloat(row[sensorPos[schemaIndex]]);
						data[schemaIndex] = value;
					} catch (NumberFormatException e) {
						e.printStackTrace();
						data[schemaIndex] = Float.NaN;
					}
				} else {
					data[schemaIndex] = Float.NaN;
				}
			}

			//TimeSeriesEntry timeSeriesEntry = new TimeSeriesEntry(timestamp, data);

			eventMap.put(timestamp,new Event((Object[])data, timestamp));

			//System.out.println(timeSeriesEntry);

		}


		bufferedReader.close();
		
		//util.Util.printArray(columnNames," ");
		
		return new KiLiCSV(serialnumber, eventMap, timestampStart, timestampEnd);


	}
	

	
	
	public void toEvents(TsDB timeSeriesDatabase, TimestampSeries timestampSeries, String schema) {
		
	}

}
