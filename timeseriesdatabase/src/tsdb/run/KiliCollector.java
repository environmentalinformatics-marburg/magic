package tsdb.run;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.CopyOption;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map.Entry;
import java.util.TreeMap;

import javax.xml.bind.DatatypeConverter;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.ki.AscParser;
import tsdb.loader.ki.TimeSeriesLoaderKiLi;
import tsdb.util.TimeConverter;
import tsdb.util.Util;
import tsdb.util.iterator.TimestampSeries;

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
		public String logger;
		public Long filesize;
		public String md5;

		public CollectorEntry(String filename) {
			this.filename = filename;
			this.status = "init";
			this.station = null;
			this.firstTimestamp = -1;
			this.lastTimestamp = -1;
			this.plot = null;
			this.logger = null;
			this.filesize = null;
			this.md5 = null;
		}

		/*public static final Comparator<CollectorEntry> LOGGER_FIRST_TIMESTAMP_COMPARATOR = new Comparator<KiliCollector.CollectorEntry>() {			
			@Override
			public int compare(CollectorEntry a, CollectorEntry b) {
				if(a.logger==null) {
					if(b.logger!=null) {
						return -1;
					}
				} else {
					if(b.logger==null) {
						return 1;
					} else {
						int c = a.logger.compareTo(b.logger);
						if(c!=0) {
							return c;
						}
					}
				}				

				int c = Integer.compare(a.firstTimestamp, b.firstTimestamp);
				if(c!=0) {
					return c;
				} else {
					return Integer.compare(a.lastTimestamp, b.lastTimestamp);
				}				
			}
		};*/



		public String toCSVRow() {
			return plot+","+logger+","+station+","+TimeConverter.oleMinutesToText((long) firstTimestamp)+","+TimeConverter.oleMinutesToText((long) lastTimestamp)+","+status+","+md5+","+filesize+","+filename;
		}

		public String createNewFilename() {
			String s = plot==null?"xxxx":plot;
			s += "_";
			s += logger==null?"xxx":logger;
			s += "_";
			s += station==null?"xxxx":station;
			s += "___";
			s += TimeConverter.oleMinutesToDateTimeFileText(this.firstTimestamp);
			s += "___";
			s += TimeConverter.oleMinutesToDateTimeFileText(this.lastTimestamp);
			s += ".asc";
			return s;
		}
	}

	public KiliCollector(TsDB tsdb) {
		this.tsdb = tsdb;
		this.timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(tsdb);		
	}



	public static void main(String[] args) throws FileNotFoundException {

		final  String PREPROCESS_PATH = "c:/timeseriesdatabase_preprocess";

		final String station_scan_path = "c:/timeseriesdatabase_preprocess"+"/"+"preprocessed_log";

		System.out.println("start...");

		TsDB tsdb = TsDBFactory.createDefault();
		KiliCollector kiliCollector = new KiliCollector(tsdb);

		HashMap<String, CollectorEntry> collectorMapBasis = kiliCollector.readDirectory_with_stations_flat(Paths.get("c:/timeseriesdatabase_preprocess/ki_tsm"));
		//HashMap<String, CollectorEntry> collectorMapBasis = kiliCollector.readDirectory_with_stations_flat(Paths.get("c:/timeseriesdatabase_preprocess/empty"));	
		TreeMap<String, List<CollectorEntry>> md5MapBasis = createMD5Map(collectorMapBasis);

		HashMap<String, CollectorEntry> collectorMapToAdd1 = kiliCollector.readDirectory_with_stations_flat(Paths.get("c:/timeseriesdatabase_preprocess/source"));



		String pathLogAllFiles = station_scan_path+"/"+"all_files.csv";
		Util.createDirectoriesOfFile(pathLogAllFiles);
		PrintStream outAllFiles = new PrintStream(new FileOutputStream(pathLogAllFiles));
		for(CollectorEntry entry:collectorMapToAdd1.values()) {
			outAllFiles.println(entry.toCSVRow());
		}
		outAllFiles.close();






		TreeMap<String, List<CollectorEntry>> md5MapToAdd = createMD5Map(collectorMapToAdd1);

		String pathLogNewFiles = station_scan_path+"/"+"new_files.csv";
		Util.createDirectoriesOfFile(pathLogNewFiles);
		PrintStream outNewFiles = new PrintStream(new FileOutputStream(pathLogNewFiles));
		String pathLogNewDuplicateFiles = station_scan_path+"/"+"new_duplicate_files.csv";
		Util.createDirectoriesOfFile(pathLogNewDuplicateFiles);
		PrintStream outNewDuplicateFiles = new PrintStream(new FileOutputStream(pathLogNewDuplicateFiles));
		HashMap<String, CollectorEntry> collectorMapProcessed = new HashMap<String, CollectorEntry>();
		for(Entry<String, List<CollectorEntry>> entry:md5MapToAdd.entrySet()) {
			String md5Key = entry.getKey();
			if(!md5MapBasis.containsKey(md5Key)) {
				CollectorEntry toAddEntry = entry.getValue().get(0);
				collectorMapProcessed.put(toAddEntry.filename,toAddEntry);
				outNewFiles.println(toAddEntry.toCSVRow());

				if(entry.getValue().size()>1) {
					for(CollectorEntry e:entry.getValue()) {
						outNewDuplicateFiles.println(e.toCSVRow());
					}
					outNewDuplicateFiles.println();
				}

			} else {
				System.out.println("duplicate "+entry.getValue().get(0).filename);
			}
		}
		outNewFiles.close();
		outNewDuplicateFiles.close();

		String PREPROCESSED_PATH = Paths.get(PREPROCESS_PATH,"preprocessed").toString();
		String PREPROCESSED_EMPTY_PATH = Paths.get(PREPROCESS_PATH,"preprocessed_empty").toString();
		String PREPROCESSED_ERROR_PATH = Paths.get(PREPROCESS_PATH,"preprocessed_error").toString();
		String PREPROCESSED_NO_PLOT_PATH = Paths.get(PREPROCESS_PATH,"preprocessed_no_plot").toString();

		String pathLogNewEmptyFiles = station_scan_path+"/"+"new_empty_files.csv";
		Util.createDirectoriesOfFile(pathLogNewEmptyFiles);
		PrintStream outNewEmptyFiles = new PrintStream(new FileOutputStream(pathLogNewEmptyFiles));

		for(CollectorEntry collectorEntry:collectorMapProcessed.values()) {			
			try {
				Path source = Paths.get(collectorEntry.filename);
				String filename = source.toFile().getName();

				String targetRoot = PREPROCESSED_ERROR_PATH;
				switch(collectorEntry.status) {
				case "ok":
					//targetRoot = Paths.get(PREPROCESSED_PATH,collectorEntry.plot).toString();
					targetRoot = Paths.get(PREPROCESSED_PATH).toString();
					filename = collectorEntry.createNewFilename();
					break;			
				case "empty":
					targetRoot = PREPROCESSED_EMPTY_PATH;
					outNewEmptyFiles.println();
					break;
				case "no properties found in station":
					targetRoot = PREPROCESSED_NO_PLOT_PATH;
					break;
				default:
					//nothing
				}

				if(filename.equals("sav0_wxt_80031130066__2013_01_16__2013_01_26.asc")) {
					System.out.println(collectorEntry.filename);
				}


				Path target = Paths.get(targetRoot, filename);
				CopyOption options = StandardCopyOption.COPY_ATTRIBUTES;
				Util.createDirectoriesOfFile(target.toString());
				Files.copy(source, target, options);
				//System.out.println(target);
			} catch(Exception e) {
				log.error(e+"  "+collectorEntry.filename);
			}
		}

		outNewEmptyFiles.close();


		System.out.println("collectorMapBasis "+collectorMapBasis.size());
		System.out.println("md5MapBasis "+md5MapBasis.size());
		System.out.println("collectorMapToAdd1 "+collectorMapToAdd1.size());
		System.out.println("md5MapToAdd "+md5MapToAdd.size());
		System.out.println("collectorMapProcessed "+collectorMapProcessed.size());

		System.out.println("...finished");
	}

	public HashMap<String, CollectorEntry> readDirectory_with_stations_flat(Path root) {
		log.info("load directory with directories of files:      "+root);		
		TreeMap<String,Path> ascCollectorMap = new TreeMap<String,Path>();		
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(root);
			for(Path subPath:stream) {
				if(Files.isDirectory(subPath)) {
					timeseriesloaderKiLi.readOneDirectory_structure_kili(subPath, ascCollectorMap,false);
				} else {
					log.warn("file in root directory: "+subPath+"   of   "+root);
				}
			}
			stream.close();
		} catch (IOException e) {
			log.error(e);
		}
		return readWithAscCollectorMap(ascCollectorMap);
	}


	public HashMap<String, CollectorEntry> readDirectory_with_asc_recursive(Path root) {
		log.info("load directory with directories of files:      "+root);		
		TreeMap<String,Path> ascCollectorMap = new TreeMap<String,Path>();
		readDirectory_with_asc_recursive_internal(root,ascCollectorMap);
		return readWithAscCollectorMap(ascCollectorMap);
	}

	private void readDirectory_with_asc_recursive_internal(Path root, TreeMap<String,Path> ascCollectorMap) {
		try {
			readDirectory_with_asc_files(root, ascCollectorMap);
		} catch (Exception e) {
			log.error(e);
		}

		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(root);
			for(Path subPath:stream) {
				if(Files.isDirectory(subPath)) {
					readDirectory_with_asc_recursive_internal(subPath,ascCollectorMap);
				} 
			}
			stream.close();
		} catch (IOException e) {
			log.error(e);
		}		
	}

	private void readDirectory_with_asc_files(Path directory_path, TreeMap<String,Path> ascCollectorMap) {
		try {
			if(Files.exists(directory_path)) {
				DirectoryStream<Path> stream = Files.newDirectoryStream(directory_path);
				//log.info("read directory of files:    "+directory_path);
				for(Path path:stream) {
					if(!Files.isDirectory(path)) {
						String filename = path.getName(path.getNameCount()-1).toString();
						int ascIndex = filename.toLowerCase().indexOf(".asc");
						if(ascIndex!=-1) {	
							String fileKey = filename.substring(0, ascIndex);						
							if(!ascCollectorMap.containsKey(fileKey)) {
								ascCollectorMap.put(fileKey, path);		
							} else {
								log.error("file key already present: "+fileKey);
							}										
						} else {
							int binIndex = filename.toLowerCase().indexOf(".bin");
							if(binIndex<0) {
								log.warn("no asc file: "+filename);
							}
						}
					}
				}
				stream.close();
			} else {
				log.warn("directory not found: "+directory_path);
			}
		} catch (IOException e) {
			log.error(e);
		}		
	}

	private static String getMD5(Path filename) {
		try {
			MessageDigest md5 = MessageDigest.getInstance("md5");
			byte[] bytes = Files.readAllBytes(filename);
			byte[] checksum = md5.digest(bytes);
			return DatatypeConverter.printHexBinary(checksum);
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public HashMap<String, CollectorEntry> readWithAscCollectorMap(TreeMap<String,Path> ascCollectorMap) {

		HashMap<String, CollectorEntry> collectorMap = new HashMap<String,CollectorEntry>();

		String currentInfoPrefix = "";

		//int counter = 0;
		for(Entry<String, Path> ascMapEntry:ascCollectorMap.entrySet()) {

			/*if(counter>100) {
				break;
			}*/
			//counter++;

			String infoFilename = ascMapEntry.getKey();
			Path ascPath = ascMapEntry.getValue();

			CollectorEntry collectorEntry = new CollectorEntry(ascPath.toString());
			if(!collectorMap.containsKey(ascPath.toString())) {
				collectorMap.put(ascPath.toString(),collectorEntry);
			} else {
				log.error("error duplicate filename");
			}

			collectorEntry.md5 = getMD5(ascPath);

			try {
				collectorEntry.filesize = ascPath.toFile().length();
			} catch(Exception e) {
				log.error(e);
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
				collectorEntry.logger = properties.get_logger_type_name();

				collectorEntry.status = "ok";

			} catch (Exception e) {
				collectorEntry.status = "error";
				e.printStackTrace();
				log.error(e+"  in  "+infoFilename);
			}
		}

		return collectorMap;
	}

	private static TreeMap<String, List<CollectorEntry>> createMD5Map(HashMap<String, CollectorEntry> collectorMap) {
		TreeMap<String, List<CollectorEntry>> md5Map = new TreeMap<String,List<CollectorEntry>>();

		for(CollectorEntry collectorEntry : collectorMap.values()) {
			String key = collectorEntry.md5;
			if(key==null) {
				key = "unknown";
			}
			List<CollectorEntry> entryList = md5Map.get(key);
			if(entryList==null) {
				entryList = new ArrayList<CollectorEntry>();
				md5Map.put(key,entryList);
			}
			entryList.add(collectorEntry);
		}

		return md5Map;
	}

}
