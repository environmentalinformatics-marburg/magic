package timeseriesdatabase; 

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import au.com.bytecode.opencsv.CSVReader;
import dat_decode.SensorData;
import dat_decode.UniversalDataBinFile;
import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import de.umr.jepc.store.EventStore;
import de.umr.jepc.util.enums.CapacityUnit;


public class Database {
	
	private static final Logger log = LogManager.getLogger("general");
	
	//StationID -> Station
	private Map<String, Station> stationMap;
	
	//LoggerType -> Logger
	private Map<String,timeseriesdatabase.Logger> loggerMap;
	
	private Map<String,GeneralStation> generalStationMap;
	
	private Storage storage;

	
	public Database() {
		stationMap = new HashMap<String, Station>();
		loggerMap = new HashMap<String, timeseriesdatabase.Logger>();
		generalStationMap = new HashMap<String,GeneralStation>();
		storage = new Storage();
	}
	
	public void close() {
		storage.close();
	}
	
	/**
	 * Read files of all exploratories.
	 * @param exploratoriesPath
	 */
	public void loadDirectoryOfAllExploratories(Path exploratoriesPath) {
		log.info("load exploratories:\t"+exploratoriesPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(exploratoriesPath);
			for(Path path:stream) {
				loadDirectoryOfOneExploratory(path);
			}
		} catch (IOException e) {
			log.error(e);
		}
		
	}
	
	/**
	 * Read files of one exploratory
	 * @param exploratoriyPath
	 */
	public void loadDirectoryOfOneExploratory(Path exploratoriyPath) {
		log.info("load exploratory:\t"+exploratoriyPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(exploratoriyPath);
			for(Path stationPath:stream) {
				String stationID = stationPath.subpath(stationPath.getNameCount()-1, stationPath.getNameCount()).toString();
				
				//*** workaround for directory names ***
				
				if(stationID.startsWith("HG")) {
					stationID = "HEG"+stationID.substring(2);
				}
				
				//**********************************
				
				
				if(!stationMap.containsKey(stationID)) {
					log.error("station does not exist in database:\t"+stationID);
				} else {				
					//createStation(stationID);
					Station station = stationMap.get(stationID);
					station.loadDirectoryOfOneStation(stationPath);
				}
			}
		} catch (IOException e) {
			log.error(e);
		}
		
	}
	
	/**
	 * Create entry for one station
	 * @param stationID
	 */
	public void createStation(String stationID, Map<String,String> propertyMap) {		
		if(stationMap.containsKey(stationID)) {
			log.warn("station already exists: "+stationID);
			return;
		}
		String generalStationName = stationID.substring(0, 3);
		System.out.println("createStation: "+generalStationName+"\t"+stationID);		
		Station station = new Station(this, generalStationName, stationID, storage, propertyMap);
		stationMap.put(stationID, station);
	}
	
	public Storage getStorage() {
		return storage;
	}
	
	public void configureStations(String config_file) {
		Map<String,List<Map<String,String>>> plotIdMap = readStationConfig(config_file);
		
		for(Entry<String, List<Map<String, String>>> entryMap:plotIdMap.entrySet()) {
			if(entryMap.getValue().size()!=1) {
				log.error("multiple properties for one station not implemented:\t"+entryMap.getValue());
			} else {
				createStation(entryMap.getKey(),entryMap.getValue().get(0));
			}
		}
	}
	
	private static Map<String,List<Map<String,String>>> readStationConfig(String config_file) {
		try {
			CSVReader reader = new CSVReader(new FileReader(config_file));
			List<String[]> list = reader.readAll();
			
			String[] names = list.get(0);
			
			final String NAN_TEXT = "NaN";
			
			Map<String,Integer> nameMap = new HashMap<String,Integer>();
			
			for(int i=0;i<names.length;i++) {
				if(!names[i].equals(NAN_TEXT)) {
					if(nameMap.containsKey(names[i])) {
						log.error("dublicate name: "+names[i]);
					} else {
						nameMap.put(names[i], i);
					}
				}
			}
			
			
			String[][] values = new String[list.size()-1][];
			
			for(int i=1;i<list.size();i++) {
				values[i-1] = list.get(i);
			}
			
			Map<String,List<Map<String,String>>> plotidMap = new HashMap<String,List<Map<String,String>>>();
			
			int plotidIndex = nameMap.get("PLOTID");
			for(String[] row:values) {
				String plotid = row[plotidIndex];
				List<Map<String,String>> entries = plotidMap.get(plotid);
				if(entries==null) {
					entries = new ArrayList<Map<String,String>>(1);
					plotidMap.put(plotid, entries);
				}
				
				
				
				Map<String,String> valueMap = new HashMap<String, String>();
				for(Entry<String, Integer> mapEntry:nameMap.entrySet()) {
					
					String value = row[mapEntry.getValue()];
					if(!value.toUpperCase().equals(NAN_TEXT.toUpperCase())) {
						valueMap.put(mapEntry.getKey(), value);
					}
					
					
					
				}
				
				entries.add(valueMap);
			}
			
			/*
			for(List<Map<String, String>> v:plotidMap.values()) {
				System.out.println(v);
			}
			*/
			
			return plotidMap;
			
			
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
		
		
	}
	
	public Map<String, Station> getStations() {
		return stationMap;
	}
	
	public Station getStation(String stationID) {
		return stationMap.get(stationID);
	}
	
	private Map<String, String> readSensorNameMap(Section section) {
		Map<String,String> sensorNameMap = new HashMap<String, String>();
		for(String key:section.keySet()) {
			if(!key.equals("NaN")) {
				//System.out.println(key+" -> "+section.get(key));
				sensorNameMap.put(key, section.get(key));
			}
		}
		return sensorNameMap;
	}
	
	public void readLoggerConfig(String config_file) {
		System.out.println(("readLoggerConfig start..."));

		try {
			
			String[] loggerTypeNames = new String[]{"00CEMU","00EEMU","00AEMU"};
			
			final String SENSOR_NAME_CONVERSION_HEADER_POSTFIX = "_header_0000";

			Wini ini = new Wini(new File(config_file));
			
			for(String loggerTypeName:loggerTypeNames) {
				System.out.println("read config for "+loggerTypeName);
				Section section = ini.get(loggerTypeName+SENSOR_NAME_CONVERSION_HEADER_POSTFIX);
				
				Map<String,String> sensorNameMap = readSensorNameMap(section);
				
				timeseriesdatabase.Logger logger = new timeseriesdatabase.Logger(loggerTypeName, sensorNameMap);
				
				loggerMap.put(loggerTypeName, logger);
			}
			
			String[] plots = {"AEG","AEW","HEG","HEW","SEG","SEW"};
			
			String suffix = "_soil_parameters_header_0000";

			for(Section section:ini.values()) {
				String sectionName=section.getName();
				
				
				System.out.println("section: "+sectionName);
				
				for(String plot:plots) {
					String prefix = "000"+plot;
					if(sectionName.startsWith(prefix)) {
						System.out.println("OK");
						String general = prefix+"xx"+suffix;
						if(sectionName.equals(general)) {
							System.out.println("general");
							
							Map<String,String> sensorNameMap = readSensorNameMap(section);							
							GeneralStation generalStation = new GeneralStation(plot, sensorNameMap);
							if(!generalStationMap.containsKey(plot)) {
								generalStationMap.put(plot, generalStation);
							} else {
								log.warn("GeneralStation already exists: "+plot);
							}
							
						} else if(sectionName.endsWith(suffix)) {
							String name = sectionName.substring(3, 8);
							System.out.println("special: "+name);
							
							Map<String,String> sensorNameMap = readSensorNameMap(section);
							
							if(stationMap.get(name)!=null) {
								stationMap.get(name).setSensorNameMap(sensorNameMap);
							} else {
								log.warn("station does not exist: "+name);
							}							
						} else {
							System.out.println("not found: "+sectionName);
						}
					}
				}
				
			}
/*
			Section section = ini.get("00CEMU_header_0000");
			System.out.println("section name: "+section.getName());
			Map<String,String> sensorNameMap = new HashMap<String, String>();
			for(String key:section.keySet()) {
				//System.out.println("key: "+key);
				//System.out.println("value: "+section.get(key));
				//System.out.println(key+" -> "+section.get(key));
				sensorNameMap.put(key, section.get(key));
			}

			System.out.println("sensorNameMap: "+sensorNameMap);*/

		} catch (Exception e) {
			log.error(e);
		}

		System.out.println("...readLoggerConfig end");		



	}
	
	public timeseriesdatabase.Logger getLogger(String loggerTypeName) {
		return loggerMap.get(loggerTypeName);
	}
	
	public GeneralStation getGeneralStation(String generalStationName) {
		return generalStationMap.get(generalStationName);
	}

	

}
