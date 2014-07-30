package timeseriesdatabase.raw;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.spi.FileSystemProvider;
import java.sql.Time;
import java.text.DateFormat;
import java.text.ParseException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.FormatStyle;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.Locale;
import java.util.TreeMap;
import java.util.stream.Stream;

import javax.management.RuntimeErrorException;

import org.apache.commons.lang3.StringUtils;

import com.sun.corba.se.impl.javax.rmi.CORBA.Util;

import de.umr.jepc.store.Event;
import timeseriesdatabase.TimeConverter;

public class KiLiCSV {

	public final String serial;
	public final TreeMap<Long, Event> eventMap;

	public KiLiCSV(String serial, TreeMap<Long, Event> eventMap) {
		this.serial = serial;
		this.eventMap = eventMap;
	}



	public static KiLiCSV readFile(Path path) throws IOException {

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
			String name = columnHeaders[i].substring(0, columnHeaders[i].indexOf("["));
			//System.out.println("name: "+name);
			columnNamesList.add(name);
		}		
		String[] columnNames = columnNamesList.toArray(new String[0]);


		TreeMap<Long, Event> eventMap = new TreeMap<Long, Event>();

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
				util.Util.printArray(columnNames,";");
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
			//System.out.println(datetime+" "+timestamp);

			Float[] data = new Float[columnNames.length-2];
			for(int colIndex=2;colIndex<columnNames.length;colIndex++) {
				try {
					float value = Float.parseFloat(row[colIndex]);
					data[colIndex-2] = value;
				} catch (NumberFormatException e) {
					e.printStackTrace();
					data[colIndex-2] = Float.NaN;
				}
				//System.out.println(value);
			}

			//TimeSeriesEntry timeSeriesEntry = new TimeSeriesEntry(timestamp, data);

			eventMap.put(timestamp,new Event((Object[])data, timestamp));

			//System.out.println(timeSeriesEntry);

		}


		bufferedReader.close();
		
		util.Util.printArray(columnNames," ");
		
		return new KiLiCSV(serialnumber, eventMap);


	}

}
