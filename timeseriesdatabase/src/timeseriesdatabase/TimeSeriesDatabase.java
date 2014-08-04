package timeseriesdatabase;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EventListener;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.BasicMultiMap;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.aggregated.Interpolator;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.raw.CSVTimeSeries;
import timeseriesdatabase.raw.KiLiCSV;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Table;
import util.TimeSeriesSchema;
import util.Util;
import util.Util.FloatRange;
import util.iterator.SchemaIterator;
import au.com.bytecode.opencsv.CSVReader;
import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.btree.TimeSplitBTreeEventStore;
import de.umr.jepc.util.enums.TimeRepresentation;

/**
 * This is the main class of the timeseries database.
 * @author woellauer
 *
 */
public class TimeSeriesDatabase {

	private static final Logger log = Util.log;

	/**
	 * EventStore is the storage of all time series
	 */
	//public TimeSplitBTreeEventStore store;
	public StreamStorage streamStorage;

	/**
	 * station/logger type name	->	LoggerType Object
	 * 00CEMU, ...
	 */
	public Map<String,LoggerType> loggerTypeMap;

	/**
	 * plot id	->	Station Object
	 * HEG01, ...
	 */
	public Map<String,Station> stationMap;

	/**
	 * general station name	->	GeneralStation Object
	 * HEG, HEW, ...
	 */
	public Map<String,GeneralStation> generalStationMap;

	/**
	 * sensor name	->	Sensor Object
	 * Ta_200, ...
	 */
	public Map<String,Sensor> sensorMap;

	/**
	 * set of sensor names of input files, that should not be stored in database
	 */
	public Set<String> ignoreSensorNameSet;

	/**
	 * set of sensor name, that should be included in base aggregation processing
	 */
	public Set<String> baseAggregationSensorNameSet;

	public CacheStorage cacheStorage;

	public Map<String,VirtualPlot> virtualplotMap; // TODO change

	/**
	 * create a new TimeSeriesDatabase object and connects to stored database files
	 * @param databasePath
	 * @param evenstoreConfigFile
	 */
	public TimeSeriesDatabase(String databasePath, String evenstoreConfigFile, String cachePath) {		
		log.trace("create TimeSeriesDatabase");		

		this.streamStorage = new StreamStorageEventStore(databasePath, evenstoreConfigFile);
		//this.streamStorage = new StreamStorageMapDB(databasePath);
		loggerTypeMap = new HashMap<String, LoggerType>();
		stationMap = new TreeMap<String,Station>();//new HashMap<String,Station>();
		generalStationMap = new HashMap<String, GeneralStation>();
		sensorMap = new TreeMap<String,Sensor>();//new HashMap<String,Sensor>();
		ignoreSensorNameSet = new HashSet<String>();
		baseAggregationSensorNameSet = new HashSet<String>();

		this.cacheStorage = new CacheStorage(cachePath);

		this.virtualplotMap = new TreeMap<String, VirtualPlot>();
	}

	public Attribute[] createAttributes(String[] names) {
		Attribute[] result = new Attribute[names.length];
		for(int i=0;i<names.length;i++) {
			result[i] = new Attribute(names[i],DataType.FLOAT);
		}
		return result;
	}

	/**
	 * for each station type read schema of data, only data of names in this schema is included in the database
	 * This method creates LoggerType Objects
	 * @param configFile
	 */
	public void readLoggerSchemaConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			for(String typeName:ini.keySet()) {
				Section section = ini.get(typeName);
				List<String> names = new ArrayList<String>();			
				for(String name:section.keySet()) {
					names.add(name);
				}
				String[] sensorNames = new String[names.size()];
				//Attribute[] schema = new Attribute[names.size()+1];  // TODO: remove "sampleRate"?   //removed !!!
				Attribute[] schema = new Attribute[names.size()];
				for(int i=0;i<names.size();i++) {
					String sensorName = names.get(i);
					sensorNames[i] = sensorName;
					schema[i] =  new Attribute(sensorName,DataType.FLOAT);
					if(sensorMap.containsKey(sensorName)) {
						// log.info("sensor already exists: "+sensorName+" new in "+typeName);
					} else {
						sensorMap.put(sensorName, new Sensor(sensorName));
					}
				}
				//schema[sensorNames.length] = new Attribute("sampleRate",DataType.SHORT);  // TODO: remove "sampleRate"?   //removed !!!
				loggerTypeMap.put(typeName, new LoggerType(typeName, sensorNames,schema));
			}
		} catch (Exception e) {
			log.error(e);
		}
	}

	/**
	 * read list of sensors that should be included in gap filling processing
	 * @param configFile
	 */
	public void readInterpolationSensorNameConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("interpolation_sensors");
			for(String name:section.keySet()) {
				Sensor sensor = sensorMap.get(name);
				if(sensor!=null) {
					sensor.useInterpolation = true;
				} else {
					log.warn("interpolation config: sensor not found: "+name);
				}
			}

		} catch (Exception e) {
			log.error(e);
		}
	}

	/**
	 * reads properties of stations and creates Station Objects
	 * @param configFile
	 */
	public void readStationConfig(String configFile) {
		Map<String,List<Map<String,String>>> plotIdMap = readStationConfigInternal(configFile);

		for(Entry<String, List<Map<String, String>>> entryMap:plotIdMap.entrySet()) {
			if(entryMap.getValue().size()!=1) {
				log.error("multiple properties for one station not implemented:\t"+entryMap.getValue());
			} else {
				String plotID = entryMap.getKey();
				String generalStationName = plotID.substring(0, 3);

				LoggerType loggerType = loggerTypeMap.get(entryMap.getValue().get(0).get("LOGGER")); 
				if(loggerType!=null) {
					Station station = new Station(this, generalStationName, plotID, loggerType, entryMap.getValue().get(0), entryMap.getValue());
					stationMap.put(plotID, station);
				} else {
					log.error("logger type not found: "+entryMap.getValue().get(0).get("LOGGER")+" -> station not created: "+plotID);
				}			

			}
		}	
	}

	/**
	 * reads properties of stations
	 * @param configFile
	 */
	private static Map<String,List<Map<String,String>>> readStationConfigInternal(String config_file) {
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
			return plotidMap;			
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}


	private static String loggerPropertyKiLiToLoggerName(String s) {
		if((s.charAt(0)>='0'&&s.charAt(0)<='9')&&(s.charAt(1)>='0'&&s.charAt(1)<='9')&&(s.charAt(2)>='0'&&s.charAt(2)<='9')){
			return s.substring(3);
		} else {
			return s;
		}
	}

	private static String plotIdKiLiToGeneralStationName(String s) {
		if(s.length()==4&&s.charAt(3)>='0'&&s.charAt(3)<='9') {
			return s.substring(0, 3);
		} else {
			return s; // not general station
		}
	}


	/**
	 * reads properties of stations and creates Station Objects
	 * @param configFile
	 */
	public void readKiLiStationConfig(String configFile) { //  KiLi
		Map<String, List<Map<String, String>>> serialMap = readKiLiStationConfigInternal(configFile);
		for(Entry<String, List<Map<String, String>>> entry:serialMap.entrySet()) {
			String serial = entry.getKey();
			//Map<String, String> firstProperyMap = entry.getValue().get(0); // !!
			//final String GENERALSTATION_PROPERTY_NAME = "TYPE";
			//String firstGeneralStationName = firstProperyMap.get(GENERALSTATION_PROPERTY_NAME); // not used
			//String firstGeneralStationName = plotIdKiLiToGeneralStationName(firstProperyMap.get("PLOTID"));
			//System.out.println("generalStationName: "+generalStationName+" serial: "+serial);
			if(!stationMap.containsKey(serial)) {
				//System.out.println(serial);
				//String loggerName = loggerPropertyKiLiToLoggerName(entry.getValue().get(0).get("LOGGER"));
				String loggerName = loggerPropertyKiLiToLoggerName(entry.getValue().get(entry.getValue().size()-1).get("LOGGER"));// !! better loggerType match of inventory
				//System.out.println("logger name: "+loggerName);
				LoggerType loggerType = loggerTypeMap.get(loggerName); 
				if(loggerType!=null) {
					//Station station = new Station(this, null/*no general station*/, serial,loggerType, entry.getValue().get(0), entry.getValue()); // !!
					Station station = new Station(this, null/*no general station*/, serial,loggerType, entry.getValue().get(entry.getValue().size()-1), entry.getValue()); // !! better loggerType match of inventory
					stationMap.put(serial, station);
					for(Map<String, String> properyMap:entry.getValue()) {
						String plotid = properyMap.get("PLOTID");
						//String generalStationName = properyMap.get(GENERALSTATION_PROPERTY_NAME);
						VirtualPlot virtualplot = virtualplotMap.get(plotid);
						if(virtualplot!=null) {
							/*if(!virtualplot.generalStationName.equals(generalStationName)) {
						log.warn("different general station names: "+virtualplot.generalStationName+"\t"+generalStationName+" in "+plotid);
					}*/

							try {
								final String PROPERTY_START = "DATE_START";
								final String PROPERTY_END = "DATE_END";
								String startText = properyMap.get(PROPERTY_START);
								String endText = properyMap.get(PROPERTY_END);

								//System.out.println(startText+" - "+endText);

								Long timestampStart = null;					
								if(!startText.equals("1999-01-01")) {
									LocalDate startDate = LocalDate.parse(startText,DateTimeFormatter.ISO_DATE);
									LocalDateTime startDateTime = LocalDateTime.of(startDate, LocalTime.of(00, 00));
									timestampStart = TimeConverter.DateTimeToOleMinutes(startDateTime);
								}

								Long timestampEnd = null;
								if(!endText.equals("2099-12-31")) {
									LocalDate endDate = LocalDate.parse(endText,DateTimeFormatter.ISO_DATE);
									LocalDateTime endDateTime = LocalDateTime.of(endDate, LocalTime.of(23, 59));
									timestampEnd = TimeConverter.DateTimeToOleMinutes(endDateTime);
								}			

								//System.out.println(timestampStart+" - "+timestampEnd);					

								virtualplot.addStationEntry(station, timestampStart, timestampEnd);
							} catch (Exception e) {
								log.warn("entry not added: "+e);
							}
						} else {
							log.warn("virtual plotid not found: "+plotid+"    "+serial);
						}
					}
				} else {				
					log.error("logger type not found: "+entry.getValue().get(0).get("LOGGER")+" -> station not created: "+serial);				
				}						
			}
			else {
				log.warn("serial already inserted: "+serial);
			}
		}
	} 

	/**
	 * reads properties of stations
	 * @param configFile
	 */
	private static Map<String,List<Map<String,String>>> readKiLiStationConfigInternal(String config_file) {  //  KiLi
		try {
			CSVReader reader = new CSVReader(new FileReader(config_file));
			List<String[]> list = reader.readAll();			
			String[] names = list.get(0);			
			final String NAN_TEXT = "NaN";			
			Map<String,Integer> nameMap = new HashMap<String,Integer>(); // map: header name -> column index			
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



			Map<String,List<Map<String,String>>> serialMap = new HashMap<String,List<Map<String,String>>>();
			int serialIndex = nameMap.get("SERIAL");
			for(String[] row:values) {
				String serial = row[serialIndex];

				List<Map<String, String>> mapList = serialMap.get(serial);
				if(mapList==null) {
					mapList = new ArrayList<Map<String, String>>(1);
					serialMap.put(serial, mapList);
				}

				HashMap<String, String> properyMap = new HashMap<String,String>();

				for(Entry<String, Integer> mapEntry:nameMap.entrySet()) {
					String value = row[mapEntry.getValue()];
					//if(!value.toUpperCase().equals(NAN_TEXT.toUpperCase())) {// ?? Nan should be in property map
					properyMap.put(mapEntry.getKey(), value);
					//}					
				}				
				mapList.add(properyMap);
			}
			reader.close();
			return serialMap;			
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * registers streams for all containing stations (with stream name == plotID)
	 */
	public void registerStreams() {
		for(Station station:stationMap.values()) {
			if(station.getLoggerType()!=null) {
				log.info("register stream "+station.plotID+" with schema of "+station.getLoggerType().typeName);
				streamStorage.registerStream(station.plotID, station.getLoggerType().schema);
			} else {
				log.error("stream not registered: "+station.plotID+"   logger type not found");
			}
		}
	}

	/**
	 * clears all stream data in EventStore; deletes all database files
	 */
	public void clear() {
		streamStorage.clear();
		//store.clear();
	}

	/**
	 * close EventStore, all pending stream data is written to disk
	 */
	public void close() {
		streamStorage.close();
		//store.close();
	}

	/**
	 * loads all files of one exploratory HEG, HEW, ...
	 * directory structure example: [exploratoriyPath]/HG01/20080130_^b0_0000.dat ... 
	 * @param exploratoriyPath
	 */
	public void loadDirectoryOfOneExploratory_structure_one(Path exploratoriyPath) {
		log.info("load exploratory:\t"+exploratoriyPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(exploratoriyPath);
			for(Path stationPath:stream) {
				String stationID = stationPath.subpath(stationPath.getNameCount()-1, stationPath.getNameCount()).toString();

				//*** workaround for directory names ***

				if(stationID.startsWith("HG")) {
					stationID = "HEG"+stationID.substring(2);
				} else if(stationID.startsWith("HW")) {
					stationID = "HEW"+stationID.substring(2);
				}

				//**********************************


				if(!stationMap.containsKey(stationID)) {
					log.error("station does not exist in database:\t"+stationID);
				} else {				
					Station station = stationMap.get(stationID);
					station.loadDirectoryOfOneStation(stationPath);
				}
			}
		} catch (IOException e) {
			log.error(e);
		}

	}



	/**
	 * read config for sensors: physical minimum and maximum values
	 * @param configFile
	 */
	public void readSensorPhysicalRangeConfig(String configFile) {
		List<FloatRange> list = Util.readIniSectionFloatRange(configFile,"parameter_physical_range");
		if(list!=null) {
			for(FloatRange entry:list) {
				Sensor sensor = sensorMap.get(entry.name);
				if(sensor != null) {
					sensor.physicalMin = entry.min;
					sensor.physicalMax = entry.max;
				} else {
					log.warn("sensor not found: "+entry.name);
				}
			}
		}
	}

	public void readSensorEmpiricalRangeConfig(String configFile) {
		List<FloatRange> list = Util.readIniSectionFloatRange(configFile,"parameter_empirical_range");
		if(list!=null) {
			for(FloatRange entry:list) {
				Sensor sensor = sensorMap.get(entry.name);
				if(sensor != null) {
					sensor.empiricalMin = entry.min;
					sensor.empiricalMax = entry.max;
				} else {
					log.warn("sensor not found: "+entry.name);
				}
			}
		}
	}

	public void readSensorStepRangeConfig(String configFile) {
		List<FloatRange> list = Util.readIniSectionFloatRange(configFile,"paramter_step_range");
		if(list!=null) {
			for(FloatRange entry:list) {
				Sensor sensor = sensorMap.get(entry.name);
				if(sensor != null) {
					sensor.stepMin = entry.min;
					sensor.stepMax = entry.max;
				} else {
					log.warn("sensor not found: "+entry.name);
				}
			}
		}
	}

	/**
	 * reads config for translation of input sensor names to database sensor names
	 * @param configFile
	 */
	public void readSensorNameTranslationConfig(String configFile) {		
		final String SENSOR_NAME_CONVERSION_HEADER_SUFFIX = "_header_0000";		
		try {
			Wini ini = new Wini(new File(configFile));
			for(LoggerType loggerType:loggerTypeMap.values()) {
				log.trace("read config for "+loggerType.typeName);
				Section section = ini.get(loggerType.typeName+SENSOR_NAME_CONVERSION_HEADER_SUFFIX);
				if(section!=null) {
					loggerType.sensorNameTranlationMap = Util.readIniSectionMap(section);
				} else {
					log.warn("logger type name tranlation not found:\t"+loggerType.typeName);
				}
			}

			final String NAME_CONVERSION_HEADER_SOIL_SUFFIX = "_soil_parameters_header_0000";
			for(Section section:ini.values()) {
				String sectionName = section.getName();
				for(GeneralStation generalStation:generalStationMap.values()) {
					String prefix = "000"+generalStation.name;
					if(sectionName.startsWith(prefix)) {
						String general_section = prefix+"xx"+NAME_CONVERSION_HEADER_SOIL_SUFFIX;
						if(sectionName.equals(general_section)) {
							generalStation.sensorNameTranlationMap = Util.readIniSectionMap(section);
						} else if(sectionName.endsWith(NAME_CONVERSION_HEADER_SOIL_SUFFIX)) {
							String plotID = sectionName.substring(3, 8);
							Station station = stationMap.get(plotID);
							if(station!=null) {
								station.sensorNameTranlationMap = Util.readIniSectionMap(section);
							} else {
								log.warn("station does not exist: "+plotID);
							}
						} else {
							log.warn("unknown: "+sectionName);
						}
					}				
				}
			}
		} catch (Exception e) {
			log.error(e);
		}
	}

	/**
	 * reads names of used general stations
	 * @param configFile
	 */
	public void readGeneralStationConfig(String configFile) {		
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("general_stations");
			for(String name:section.keySet()) {
				if(generalStationMap.containsKey(name)) {
					log.warn("general station already exists: "+name);
				} else {
					generalStationMap.put(name, new GeneralStation(name));
				}
			}

		} catch (Exception e) {
			log.error(e);
		}		
	}

	/**
	 * reads names of input sensors, that should not be included in database
	 * @param configFile
	 */
	public void readIgnoreSensorNameConfig(String configFile) {		
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("ignore_sensors");
			for(String name:section.keySet()) {				
				ignoreSensorNameSet.add(name);
			}

		} catch (Exception e) {
			log.error(e);
		}	
	}

	/**
	 * reads sensor config for base aggregation: for each sensor the type of aggregation is read
	 * @param configFile
	 */
	public void readBaseAggregationConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("base_aggregation");
			if(section!=null) {
				for(String sensorName:section.keySet()) {
					Sensor sensor =sensorMap.get(sensorName);
					if(sensor!=null) {
						String aggregateTypeText = section.get(sensorName);
						AggregationType aggregateType = AggregationType.NONE;
						if(aggregateTypeText.toLowerCase().equals("average")) {
							aggregateType = AggregationType.AVERAGE;
						} else if(aggregateTypeText.toLowerCase().equals("sum")) {
							aggregateType = AggregationType.SUM;
						} else if(aggregateTypeText.toLowerCase().equals("maximum")) {
							aggregateType = AggregationType.MAXIMUM;							
						} else if(aggregateTypeText.toLowerCase().equals("average_wind_direction")) {
							aggregateType = AggregationType.AVERAGE_WIND_DIRECTION;
						} else if(aggregateTypeText.toLowerCase().equals("average_wind_velocity")) {
							aggregateType = AggregationType.AVERAGE_WIND_VELOCITY;							
						} else if(aggregateTypeText.toLowerCase().equals("average_zero")) {
							aggregateType = AggregationType.AVERAGE_ZERO;
						} else if(aggregateTypeText.toLowerCase().equals("average_albedo")) {
							aggregateType = AggregationType.AVERAGE_ALBEDO;	
						} else {
							log.warn("aggregate type unknown: "+aggregateTypeText+"\tin\t"+sensorName);
						}
						sensor.baseAggregationType = aggregateType;
						baseAggregationSensorNameSet.add(sensorName);
					} else {
						log.warn("sensor not found: "+sensorName);
					}
				}
			}
		} catch (IOException e) {
			log.warn(e);
		}		
	}

	public void readEmpiricalDiffConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("parameter_empirical_diff");
			if(section!=null) {
				for(String sensorName:section.keySet()) {
					Sensor sensor =sensorMap.get(sensorName);
					if(sensor!=null) {
						String sensorDiff = section.get(sensorName);
						float diff = Float.parseFloat(sensorDiff);
						sensor.empiricalDiff = diff;
					} else {
						log.warn("sensor not found: "+sensorName);
					}
				}
			} else {
				throw new RuntimeException("section not found");
			}
		} catch (IOException e) {
			log.warn(e);
		}		
	}

	public Float[] getEmpiricalDiff(String[] schema) {
		Float[] diff = new Float[schema.length];
		for(int i=0;i<schema.length;i++) {
			Sensor sensor = sensorMap.get(schema[i]);
			if(sensor!=null) {
				diff[i] = sensor.empiricalDiff;
			} else {
				throw new RuntimeException("sensor not found: "+schema[i]);
			}
		}
		return diff;
	}


	public void loadDirectory_with_stations_structure_two(Path rootPath) {
		log.info("loadDirectory_with_stations_structure_two:\t"+rootPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(rootPath);
			for(Path stationPath:stream) {
				System.out.println(stationPath+"\t");
				String stationID = stationPath.getName(stationPath.getNameCount()-1).toString();				
				if(!stationMap.containsKey(stationID)) {
					log.error("station does not exist in database:\t"+stationID);
				} else {				
					Station station = stationMap.get(stationID);
					Path newPath = Paths.get(stationPath.toString(),"backup");
					if(Files.exists(newPath)) {
						station.loadDirectoryOfOneStation(newPath);
					}
				}
			}
		} catch (IOException e) {
			log.error(e);
		}		
	}



	/**
	 * loads all files of all exploratories
	 * directory structure example: [exploratoriesPath]/HEG/HG01/20080130_^b0_0000.dat ... 
	 * @param exploratoriesPath
	 */
	public void loadDirectoryOfAllExploratories_structure_one(Path exploratoriesPath) {
		log.info("loadDirectoryOfAllExploratories_structure_one:\t"+exploratoriesPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(exploratoriesPath);
			for(Path path:stream) {
				System.out.println(path);
				loadDirectoryOfOneExploratory_structure_one(path);
			}
		} catch (IOException e) {
			log.error(e);
		}

	}

	public void loadDirectoryOfAllExploratories_structure_kili(Path kiliPath) {
		log.info("loadDirectoryOfAllExploratories_structure_kili:\t"+kiliPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(kiliPath);
			for(Path path:stream) {
				//loadOneDirectory_structure_kili(Paths.get(path+"/ra01_nai05_0000"));
				
				DirectoryStream<Path> subStream = Files.newDirectoryStream(path,"ra*");
				for(Path subPath:subStream) {
					loadOneDirectory_structure_kili(subPath);
				}
				
				
			}
		} catch (IOException e) {
			log.error(e);
		}

	}

	public void loadOneDirectory_structure_kili(Path kiliPath) {
		try {
			if(Files.exists(kiliPath)) {
				DirectoryStream<Path> stream = Files.newDirectoryStream(kiliPath);
				System.out.println("*** load directory: "+kiliPath+" ***");
				for(Path path:stream) {
					//System.out.println(path);

					try{
						CSVTimeSeries csvtimeSeries = new CSVTimeSeries(path);
						TimestampSeries timestampSeries = csvtimeSeries.readEntries();

						if(timestampSeries!=null) {

							if(!timestampSeries.entryList.isEmpty()) {

								Station station = stationMap.get(csvtimeSeries.serialnumber);
								if(station!=null) {

									String[] translatedInputSchema = new String[csvtimeSeries.parameterNames.length];
									for(int i=0;i<csvtimeSeries.parameterNames.length;i++) {
										translatedInputSchema[i] = station.translateInputSensorName(csvtimeSeries.parameterNames[i], false);
									}

									Map<String, Integer> schemaMap = Util.stringArrayToMap(translatedInputSchema,true);
									String PLACE_HOLDER_W_R_300_U = "PLACE_HOLDER_W_R_300_U";
									if(schemaMap.containsKey(PLACE_HOLDER_W_R_300_U)) {
										int counter_PLACE_HOLDER_W_R_300_U = 0;
										String[] entries_PLACE_HOLDER_W_R_300_U =  new String[]{"SWDR_300_U", "SWUR_300_U", "LWDR_300_U", "LWUR_300_U"};
										
										if(station.loggerType.typeName.equals("wxt")) {
											String[] entries_alternative_PLACE_HOLDER_W_R_300_U = new String[]{"LWDR_300_U", "LWUR_300_U", "SWDR_300_U", "SWUR_300_U"};
											long up_to_2011 = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2011, 8, 20,23,59));
											//TODO change entries_PLACE_HOLDER_W_R_300_U											
										}
										
										
										for(int schmaIndex=0;schmaIndex<translatedInputSchema.length;schmaIndex++) {
											if(translatedInputSchema[schmaIndex]!=null&&translatedInputSchema[schmaIndex].equals(PLACE_HOLDER_W_R_300_U)) {
												if(counter_PLACE_HOLDER_W_R_300_U<entries_PLACE_HOLDER_W_R_300_U.length) {
													translatedInputSchema[schmaIndex] = entries_PLACE_HOLDER_W_R_300_U[counter_PLACE_HOLDER_W_R_300_U];													
												} else {
													log.warn("no real name for column "+PLACE_HOLDER_W_R_300_U+" "+counter_PLACE_HOLDER_W_R_300_U);
													translatedInputSchema[schmaIndex] = null;
												}
												counter_PLACE_HOLDER_W_R_300_U++;
											}
										}
									}
									
									
									
									String PLACE_HOLDER_RT_NRT_I = "PLACE_HOLDER_RT_NRT_I";
									if(schemaMap.containsKey(PLACE_HOLDER_RT_NRT_I)) {
										int counter_PLACE_HOLDER_RT_NRT_I = 0;
										String[] entries_PLACE_HOLDER_RT_NRT_I = new String[]{"P_RT_NRT_01_I","P_RT_NRT_02_I"};
										for(int schmaIndex=0;schmaIndex<translatedInputSchema.length;schmaIndex++) {
											if(translatedInputSchema[schmaIndex]!=null&&translatedInputSchema[schmaIndex].equals(PLACE_HOLDER_RT_NRT_I)) {
												if(counter_PLACE_HOLDER_RT_NRT_I<entries_PLACE_HOLDER_RT_NRT_I.length) {
													translatedInputSchema[schmaIndex] = entries_PLACE_HOLDER_RT_NRT_I[counter_PLACE_HOLDER_RT_NRT_I];	
												} else {
													log.warn("no real name for column "+PLACE_HOLDER_RT_NRT_I+" "+counter_PLACE_HOLDER_RT_NRT_I);
													translatedInputSchema[schmaIndex] = null;
												}
												counter_PLACE_HOLDER_RT_NRT_I++;
											}
										}
									}



									TreeSet<String> duplicates = Util.getDuplicateNames(translatedInputSchema,true);
									if(!duplicates.isEmpty()) {
										log.warn("duplicates: "+duplicates+" in "+path);
									}

									String debugInfo = station.loggerType.toString();
									List<Event> eventList = csvtimeSeries.toEvents(timestampSeries, translatedInputSchema, station.loggerType.sensorNames, debugInfo);

									if(eventList!=null) {							
										streamStorage.insertEventList(csvtimeSeries.serialnumber, eventList, csvtimeSeries.timestampStart, csvtimeSeries.timestampEnd);
									} else {
										log.warn("no events inserted: "+path);
									}
								} else {
									log.error("station not found: "+csvtimeSeries.serialnumber+" in "+path);
								}
							} else {
								log.warn("timestampseries is empty");
							}
						} else {
							log.error("no timestampseries");
						}

					} catch(Exception e) {
						e.printStackTrace();
						log.error(e+" in "+path);
					}

					/*
				try {
					//System.out.println("read: "+path);
					KiLiCSV kiliCSV = KiLiCSV.readFileOLD(this,path);

					if(kiliCSV!=null) {

					if(stationMap.containsKey(kiliCSV.serial)) {
						System.out.println("insert "+kiliCSV.eventMap.size()+" into "+kiliCSV.serial);

						this.streamStorage.insertData(kiliCSV.serial, kiliCSV.eventMap);

					} else {
						log.warn("not in database: "+kiliCSV.serial);
					}

					}
				} catch(Exception e) {
					e.printStackTrace();
					log.error(e+" in "+path);
				}
					 */
				}
			} else {
				log.warn("directory not found: "+kiliPath);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}



	/**
	 * sql query on storage of raw time series
	 * (not used)
	 * @param sql
	 * @return iterator of raw sensor data
	 */
	/*public Iterator<Event> __OLD_query(String sql) {
		return store.query(sql);		
	}*/

	/**
	 * query stream of plotID within startTime and endTime
	 * (not used)
	 * @param plotID
	 * @param ParameterName
	 * @param startTime
	 * @param endTime
	 * @return iterator over the stream of plotID with full schema
	 */
	/*public  Iterator<Event> __OLD_queryTimeSeries(String plotID, long startTime, long endTime) {
		return store.getHistoryRange(plotID, startTime, endTime);		
	}*/	

	/**
	 * get array of Sensor objects with given sensor names
	 * @param outputTimeSeriesSchema
	 * @return
	 */
	public Sensor[] getSensors(TimeSeriesSchema outputTimeSeriesSchema) {
		Sensor[] sensors = new Sensor[outputTimeSeriesSchema.columns];
		for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
			Sensor sensor = sensorMap.get(outputTimeSeriesSchema.schema[i]);
			sensors[i] = sensor;
			if(sensor==null) {
				log.warn("sensor "+outputTimeSeriesSchema+" not found");
			}
		}
		return sensors;
	}

	/**
	 * read geo config of stations:
	 * 1. read geo pos of station
	 * 2. calculate ordered list for each station of stations nearest to current station within same general station
	 * @param config_file
	 */
	public void readStationGeoPositionConfig(String config_file) {
		try{		
			Table table = Table.readCSV(config_file);		
			int plotidIndex = table.getColumnIndex("PlotID");
			int epplotidIndex = table.getColumnIndex("EP_Plotid"); 
			int lonIndex = table.getColumnIndex("Lon");
			int latIndex = table.getColumnIndex("Lat");			
			for(String[] row:table.rows) {
				String plotID = row[epplotidIndex];
				if(!plotID.endsWith("_canceled")) { // ignore plotid canceled positions
					Station station = stationMap.get(plotID);
					if(station!=null) {					
						try {					
							double lon = Double.parseDouble(row[lonIndex]);
							double lat = Double.parseDouble(row[latIndex]);					
							station.geoPoslongitude = lon;
							station.geoPosLatitude = lat;					
						} catch(Exception e) {
							log.warn("geo pos not read: "+plotID);
						}
						if(plotidIndex>-1) {
							station.serialID = row[plotidIndex];
						}
					} else {
						log.warn("station not found: "+row[epplotidIndex]+"\t"+row[lonIndex]+"\t"+row[latIndex]);
					}
				}

			}

		} catch(Exception e) {
			log.error(e);
		}		
		calcNearestStations();		
	}

	/*public void readKiLiStationGeoPositionConfig(String config_file) {  //TODO
		try{		
			Table table = Table.readCSV(config_file);		
			int plotidIndex = table.getColumnIndex("PlotID");
			int epplotidIndex = table.getColumnIndex("EP_Plotid"); 
			int lonIndex = table.getColumnIndex("Lon");
			int latIndex = table.getColumnIndex("Lat");			
			for(String[] row:table.rows) {
				String plotID = row[epplotidIndex];
				if(!plotID.endsWith("_canceled")) { // ignore plotid canceled positions
					Station station = stationMap.get(plotID);
					if(station!=null) {					
						try {					
							double lon = Double.parseDouble(row[lonIndex]);
							double lat = Double.parseDouble(row[latIndex]);					
							station.geoPoslongitude = lon;
							station.geoPosLatitude = lat;					
						} catch(Exception e) {
							log.warn("geo pos not read: "+plotID);
						}
						if(plotidIndex>-1) {
							station.serialID = row[plotidIndex];
						}
					} else {
						log.warn("station not found: "+row[epplotidIndex]+"\t"+row[lonIndex]+"\t"+row[latIndex]);
					}
				}

			}

		} catch(Exception e) {
			log.error(e);
		}		
		calcNearestStations();		
	}*/


	public void updateGeneralStations() {

		for(GeneralStation g:generalStationMap.values()) {
			g.stationList = new ArrayList<Station>();
			g.virtualPlotList = new ArrayList<VirtualPlot>();
		}

		for(Station station:stationMap.values()) {
			if(station.generalStationName!=null) {
				GeneralStation generalStation = generalStationMap.get(station.generalStationName);
				if(generalStation!=null) {
					generalStation.stationList.add(station);
				} else {
					log.warn("general station not found: "+station.generalStationName+" in "+station.plotID);
				}
			}
		}

		for(VirtualPlot virtualplot:virtualplotMap.values()) {
			if(virtualplot.generalStationName!=null) {
				GeneralStation generalStation = generalStationMap.get(virtualplot.generalStationName);
				if(generalStation!=null) {
					generalStation.virtualPlotList.add(virtualplot);
				} else {
					log.warn("general station not found: "+virtualplot.generalStationName+" in "+virtualplot.plotID);
				}
			}
		}

	}

	public void calcNearestStations() {
		updateGeneralStations();

		for(Station station:stationMap.values()) {


			double[] geoPos = transformCoordinates(station.geoPoslongitude,station.geoPosLatitude);

			List<Object[]> differenceList = new ArrayList<Object[]>();

			List<Station> stationList = generalStationMap.get(station.generalStationName).stationList;
			//System.out.println(station.plotID+" --> "+stationList);
			for(Station targetStation:stationList) {
				if(station!=targetStation) { // reference compare
					double[] targetGeoPos = transformCoordinates(targetStation.geoPoslongitude,targetStation.geoPosLatitude);
					double difference = getDifference(geoPos, targetGeoPos);
					differenceList.add(new Object[]{difference,targetStation});
				}
			}

			differenceList.sort(new Comparator<Object[]>() {

				@Override
				public int compare(Object[] o1, Object[] o2) {
					double d1 = (double) o1[0];
					double d2 = (double) o2[0];					
					return Double.compare(d1, d2);
				}
			});

			List<Station> targetStationList = new ArrayList<Station>(differenceList.size());
			for(Object[] targetStation:differenceList) {
				targetStationList.add((Station) targetStation[1]);
			}

			station.nearestStationList = targetStationList;
			//System.out.println(station.plotID+" --> "+station.nearestStationList);
		}

	}

	public static double[] transformCoordinates(double longitude, double latitude) {
		// TODO: do real transformation
		return new double[]{longitude,latitude};
	}

	public static double getDifference(double[] geoPos, double[] targetGeoPos) {
		return Math.sqrt((geoPos[0]-targetGeoPos[0])*(geoPos[0]-targetGeoPos[0])+(geoPos[1]-targetGeoPos[1])*(geoPos[1]-targetGeoPos[1]));
	}

	public Station getStation(String plotID) {
		return stationMap.get(plotID);		
	}

	public long getFirstTimestamp(String plotID) {
		Iterator<Event> it = streamStorage.queryRawEvents(plotID, null, null);
		if(it.hasNext()) {
			return it.next().getTimestamp();
		} else {
			return -1;
		}
	}

	public long getLastTimestamp(String plotID) {
		Iterator<Event> it = streamStorage.queryRawEvents(plotID, null, null);
		long timestamp = -1;
		while (it.hasNext()) {
			timestamp = it.next().getTimestamp();
		}
		return timestamp;
	}

	public long getFirstTimestampBaseAggregated(String plotID) {
		return BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(getFirstTimestamp(plotID));
	}

	public long getLastTimestampBaseAggregated(String plotID) {
		return BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(getLastTimestamp(plotID));
	}

	public void readLoggerTypeSensorTranslationConfig(String configFile) {		
		String SENSOR_TRANSLATION_HEADER_SUFFIX = "_sensor_translation";
		try {
			Wini ini = new Wini(new File(configFile));
			for(LoggerType loggerType:loggerTypeMap.values()) {
				log.trace("read config for "+loggerType.typeName);
				Section section = ini.get(loggerType.typeName+SENSOR_TRANSLATION_HEADER_SUFFIX);
				if(section!=null) {
					System.out.println("read "+section.getName());
					loggerType.sensorNameTranlationMap = Util.readIniSectionMap(section);
				} else {
					//not all logger types may be defined in in this file
					//log.warn("logger type name tranlation not found:\t"+loggerType.typeName);
				}
			}
		} catch (IOException e) {
			log.error(e);
		}		
	}

	public void readVirtualPlotConfig(String config_file) {
		try{		
			Table table = Table.readCSV(config_file);
			int plotidIndex = table.getColumnIndex("PlotID"); // virtual plotid
			int categoriesIndex = table.getColumnIndex("Categories"); // general station

			for(String[] row:table.rows) {
				String plotID = row[plotidIndex];

				String generalStationName = row[categoriesIndex];

				if(plotID.length()==4&&plotID.charAt(3)>='0'&&plotID.charAt(3)<='9') {
					String gen = plotID.substring(0, 3);
					if(generalStationMap.containsKey(gen)) {
						generalStationName = gen;
					} else {
						log.warn("unknown general station in: "+plotID+"\t"+gen);
					}
				} else {
					log.warn("unknown general station in: "+plotID);
				}



				if(!generalStationMap.containsKey(generalStationName)) {// TODO
					log.warn("unknown general station: "+generalStationName);
				}
				VirtualPlot virtualplot = virtualplotMap.get(plotID);
				if(virtualplot==null) {
					virtualplot = new VirtualPlot(plotID, generalStationName);
					virtualplotMap.put(plotID, virtualplot);
				} else {
					log.warn("virtual plot already exists: "+plotID);
				}
			}



			/*int plotidIndex = table.getColumnIndex("PlotID");
			int epplotidIndex = table.getColumnIndex("EP_Plotid"); 
			int lonIndex = table.getColumnIndex("Lon");
			int latIndex = table.getColumnIndex("Lat");			
			for(String[] row:table.rows) {
				String plotID = row[epplotidIndex];
				if(!plotID.endsWith("_canceled")) { // ignore plotid canceled positions
					Station station = stationMap.get(plotID);
					if(station!=null) {					
						try {					
							double lon = Double.parseDouble(row[lonIndex]);
							double lat = Double.parseDouble(row[latIndex]);					
							station.geoPoslongitude = lon;
							station.geoPosLatitude = lat;					
						} catch(Exception e) {
							log.warn("geo pos not read: "+plotID);
						}
						if(plotidIndex>-1) {
							station.serialID = row[plotidIndex];
						}
					} else {
						log.warn("station not found: "+row[epplotidIndex]+"\t"+row[lonIndex]+"\t"+row[latIndex]);
					}
				}

			}*/

		} catch(Exception e) {
			log.error(e);
		}				
	}

	public String[] getBaseAggregationSchema(String[] rawSchema) {
		ArrayList<String> sensorNames = new ArrayList<String>();
		for(String name:rawSchema) {
			if(baseAggregationSensorNameSet.contains(name)) {
				sensorNames.add(name);
			}
		}
		return sensorNames.toArray(new String[0]);
	}

	public String[] getValidSchema(String stationID, String[] schema) {
		ArrayList<String> sensorNames = new ArrayList<String>();
		Map<String, Integer> map = Util.stringArrayToMap(stationMap.get(stationID).getLoggerType().sensorNames);
		for(String name:schema) {
			if(map.containsKey(name)) {
				sensorNames.add(name);
			}
		}
		return sensorNames.toArray(new String[0]);
	}
}
