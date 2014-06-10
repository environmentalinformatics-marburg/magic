package timeseriesdatabase; 

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
	
	private Storage storage;

	
	public Database() {
		stationMap = new HashMap<String, Station>();
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
					stationID = stationID.replace("HG", "HEG");
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
		Station station = new Station(stationID, storage, propertyMap);
		stationMap.put(stationID, station);
	}
	
	public Storage getStorage() {
		return storage;
	}
	
	public void configureStations(String config_file) {
		Map<String,List<Map<String,String>>> plotidMap = readConfig(config_file);
		
		for(Entry<String, List<Map<String, String>>> entryMap:plotidMap.entrySet()) {
			if(entryMap.getValue().size()!=1) {
				log.error("multiple properties for one station not implemented:\t"+entryMap.getValue());
			} else {
				createStation(entryMap.getKey(),entryMap.getValue().get(0));
			}
		}
	}
	
	private static Map<String,List<Map<String,String>>> readConfig(String config_file) {
		/*try {
			FileInputStream fileInputStream = new FileInputStream(config_file);
			Scanner scanner = new Scanner(fileInputStream);
			
			while(scanner.hasNext()) {
				scanner.useDelimiter(",");
				System.out.println("scanner.next()"+scanner.next());
				
			}
			
			
			
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}*/
		
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
			
			
			for(List<Map<String, String>> v:plotidMap.values()) {
				System.out.println(v);
			}
			
			return plotidMap;
			
			
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
		
		
	}
	
	

}
