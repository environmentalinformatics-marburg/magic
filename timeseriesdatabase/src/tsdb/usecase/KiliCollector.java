package tsdb.usecase;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.Map.Entry;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.ki.AscParser;
import tsdb.loader.ki.TimeSeriesLoaderKiLi;
import tsdb.raw.TimestampSeries;

public class KiliCollector {

	private static final Logger log = LogManager.getLogger();

	private final TsDB tsdb;	
	private final TimeSeriesLoaderKiLi timeseriesloaderKiLi;

	private static class CollectorEntry {
		public final String filename;
		public String status;
		public String station;		
		public int firstTimestamp;
		public int lastTimestamp;
		public String plot;

		public CollectorEntry(String filename) {
			this.filename = filename;
			this.status = "init";
			this.station = null;
			this.firstTimestamp = -1;
			this.lastTimestamp = -1;
			this.plot = null;
		}

		public static final Comparator<CollectorEntry> FIRST_TIMESTAMP_COMPARATOR = new Comparator<KiliCollector.CollectorEntry>() {			
			@Override
			public int compare(CollectorEntry a, CollectorEntry b) {				
				int c = Integer.compare(a.firstTimestamp, b.firstTimestamp);
				if(c!=0) {
					return c;
				} else {
					return Integer.compare(a.lastTimestamp, b.lastTimestamp);
				}
			}
		};
	}

	private Map<String,CollectorEntry> collectorMap;	

	public KiliCollector(TsDB tsdb) {
		this.tsdb = tsdb;
		this.timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(tsdb);
		this.collectorMap = new HashMap<String,CollectorEntry>();
	}

	public static void main(String[] args) throws FileNotFoundException {

		TsDB tsdb = TsDBFactory.createDefault();
		KiliCollector kiliCollector = new KiliCollector(tsdb);

		kiliCollector.readDirectory_with_stations_flat(Paths.get(TsDBFactory.SOURCE_KI_TSM_PATH));

		for(CollectorEntry collectorEntry : kiliCollector.collectorMap.values()) {
			if(!collectorEntry.status.equals("ok") && !collectorEntry.status.equals("empty")) {
				System.out.println(collectorEntry.status+ "     " + collectorEntry.filename);
			}
		}

		//PrintStream out = new PrintStream(new FileOutputStream(TsDBFactory.OUTPUT_PATH+"/"+"station_scan.csv"));

		TreeMap<String, List<CollectorEntry>> plotMap = new TreeMap<String,List<CollectorEntry>>();
		TreeMap<String, List<CollectorEntry>> stationMap = new TreeMap<String,List<CollectorEntry>>();

		String pathEmpty = TsDBFactory.OUTPUT_PATH+"/"+"station_scan"+"/"+"empty.csv";
		try {
			File dir = new File(pathEmpty);			
			dir.getParentFile().mkdirs();
		} catch(Exception e) {
			log.error(e);
		}
		PrintStream outEmpty = new PrintStream(new FileOutputStream(pathEmpty));

		String pathNoStation = TsDBFactory.OUTPUT_PATH+"/"+"station_scan"+"/"+"no_station.csv";
		try {
			File dir = new File(pathNoStation);			
			dir.getParentFile().mkdirs();
		} catch(Exception e) {
			log.error(e);
		}
		PrintStream outNoStation = new PrintStream(new FileOutputStream(pathNoStation));

		String pathStationNoPlot = TsDBFactory.OUTPUT_PATH+"/"+"station_scan"+"/"+"station_no_plot.csv";
		try {
			File dir = new File(pathStationNoPlot);			
			dir.getParentFile().mkdirs();
		} catch(Exception e) {
			log.error(e);
		}
		PrintStream outStationNoPlot = new PrintStream(new FileOutputStream(pathStationNoPlot));

		for(CollectorEntry collectorEntry : kiliCollector.collectorMap.values()) {
			if(!collectorEntry.status.equals("ok") && !collectorEntry.status.equals("empty")) {
				System.out.println(collectorEntry.status+ "     " + collectorEntry.filename);				
			}


			if(collectorEntry.station==null)  {
				outNoStation.println(collectorEntry.plot+","+collectorEntry.station+","+TimeConverter.oleMinutesToText((long) collectorEntry.firstTimestamp)+","+TimeConverter.oleMinutesToText((long) collectorEntry.lastTimestamp)+","+collectorEntry.status+","+collectorEntry.filename);
			} else if(collectorEntry.status.equals("empty")) {
				outEmpty.println(collectorEntry.plot+","+collectorEntry.station+","+TimeConverter.oleMinutesToText((long) collectorEntry.firstTimestamp)+","+TimeConverter.oleMinutesToText((long) collectorEntry.lastTimestamp)+","+collectorEntry.status+","+collectorEntry.filename);
			} else {

				if(true){
					List<CollectorEntry> entryList = stationMap.get(collectorEntry.station);
					if(entryList==null) {
						entryList = new ArrayList<CollectorEntry>();
						stationMap.put(collectorEntry.station,entryList);
					}
					entryList.add(collectorEntry);
				}

				if(collectorEntry.plot==null) {
					outStationNoPlot.println(collectorEntry.plot+","+collectorEntry.station+","+TimeConverter.oleMinutesToText((long) collectorEntry.firstTimestamp)+","+TimeConverter.oleMinutesToText((long) collectorEntry.lastTimestamp)+","+collectorEntry.status+","+collectorEntry.filename);
				} else {
					List<CollectorEntry> entryList = plotMap.get(collectorEntry.plot);
					if(entryList==null) {
						entryList = new ArrayList<CollectorEntry>();
						plotMap.put(collectorEntry.plot,entryList);
					}
					entryList.add(collectorEntry);
				}
			}
		}

		outEmpty.close();
		outNoStation.close();
		outStationNoPlot.close();

		for(Entry<String, List<CollectorEntry>> mapEntry:plotMap.entrySet()) {
			String path = TsDBFactory.OUTPUT_PATH+"/"+"station_scan"+"/"+"plot"+"/"+mapEntry.getKey()+".csv";
			try {
				File dir = new File(path);			
				dir.getParentFile().mkdirs();
			} catch(Exception e) {
				log.error(e);
			}

			PrintStream out = new PrintStream(new FileOutputStream(path));
			mapEntry.getValue().sort(CollectorEntry.FIRST_TIMESTAMP_COMPARATOR);
			for(CollectorEntry collectorEntry:mapEntry.getValue()) {
				out.println(collectorEntry.plot+","+collectorEntry.station+","+TimeConverter.oleMinutesToText((long) collectorEntry.firstTimestamp)+","+TimeConverter.oleMinutesToText((long) collectorEntry.lastTimestamp)+","+collectorEntry.status+","+collectorEntry.filename);				
			}
			out.close();
		}

		for(Entry<String, List<CollectorEntry>> mapEntry:stationMap.entrySet()) {
			String path = TsDBFactory.OUTPUT_PATH+"/"+"station_scan"+"/"+"station"+"/"+mapEntry.getKey()+".csv";
			try {
				File dir = new File(path);			
				dir.getParentFile().mkdirs();
			} catch(Exception e) {
				log.error(e);
			}

			PrintStream out = new PrintStream(new FileOutputStream(path));
			mapEntry.getValue().sort(CollectorEntry.FIRST_TIMESTAMP_COMPARATOR);
			for(CollectorEntry collectorEntry:mapEntry.getValue()) {
				out.println(collectorEntry.plot+","+collectorEntry.station+","+TimeConverter.oleMinutesToText((long) collectorEntry.firstTimestamp)+","+TimeConverter.oleMinutesToText((long) collectorEntry.lastTimestamp)+","+collectorEntry.status+","+collectorEntry.filename);				
			}
			out.close();
		}


	}

	public void readDirectory_with_stations_flat(Path root) {
		log.info("load directory with directories of files:      "+root);		
		TreeMap<String,Path> ascCollectorMap = new TreeMap<String,Path>();		
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(root);
			for(Path subPath:stream) {
				if(Files.isDirectory(subPath)) {
					timeseriesloaderKiLi.readOneDirectory_structure_kili(subPath, ascCollectorMap);
				} else {
					log.warn("file in root directory: "+subPath+"   of   "+root);
				}
			}
			stream.close();
		} catch (IOException e) {
			log.error(e);
		}
		readWithAscCollectorMap(ascCollectorMap);
	}

	public void readWithAscCollectorMap(TreeMap<String,Path> ascCollectorMap) {
		String currentInfoPrefix = "";

		int counter = 0;
		for(Entry<String, Path> ascMapEntry:ascCollectorMap.entrySet()) {

			/*if(counter>100) {
				break;
			}*/
			counter++;

			String infoFilename = ascMapEntry.getKey();
			Path ascPath = ascMapEntry.getValue();

			CollectorEntry collectorEntry = new CollectorEntry(ascPath.toString());
			if(!collectorMap.containsKey(ascPath.toString())) {
				collectorMap.put(ascPath.toString(),collectorEntry);
			} else {
				log.error("error duplicate filename");
			}			


			try {
				String infoKeyPrefix = infoFilename;
				if(infoKeyPrefix.length()>18) {
					infoKeyPrefix = infoKeyPrefix.substring(0, 18);
				}
				if(!currentInfoPrefix.equals(infoKeyPrefix)) {
					log.info("read files of prefix   "+infoKeyPrefix);
					currentInfoPrefix = infoKeyPrefix;
				}
			} catch(Exception e) {
				log.warn(e);
			}			

			try {
				TimestampSeries timestampseries = AscParser.parse(ascPath);
				if(timestampseries==null) {
					log.error("read error in "+infoFilename);
					collectorEntry.status = "read error";
					continue;
				}

				collectorEntry.station = timestampseries.name;

				if(timestampseries.entryList.isEmpty()) {
					log.info("empty timestampseries in  "+infoFilename);
					collectorEntry.status = "empty";
					continue;
				}

				collectorEntry.firstTimestamp = (int) timestampseries.getFirstTimestamp();
				collectorEntry.lastTimestamp =  (int) timestampseries.getLastTimestamp();

				Station station = tsdb.getStation(timestampseries.name);
				if(station==null) {
					log.error("station not found "+timestampseries.name+"   in  "+ascPath);
					collectorEntry.status = "station not found";
					continue;
				}

				String[] translatedInputSchema = new String[timestampseries.sensorNames.length];
				for(int i=0;i<timestampseries.sensorNames.length;i++) {
					translatedInputSchema[i] = station.translateInputSensorName(timestampseries.sensorNames[i], false);
				}

				StationProperties properties = station.getProperties(timestampseries.getFirstTimestamp(), timestampseries.getLastTimestamp());

				if(properties==null) {
					log.error("no properties found in station "+timestampseries.name+"  of  "+TimeConverter.oleMinutesToText(timestampseries.getFirstTimestamp())+" - "+TimeConverter.oleMinutesToText(timestampseries.getLastTimestamp())+"  in  "+ascPath);
					collectorEntry.status = "no properties found in station";
					continue;
				}

				collectorEntry.plot = properties.get_plotid();

				collectorEntry.status = "ok";

			} catch (Exception e) {
				collectorEntry.status = "error";
				e.printStackTrace();
				log.error(e+"  in  "+infoFilename);
			}
		}
	}

}
