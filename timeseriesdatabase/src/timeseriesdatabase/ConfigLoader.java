package timeseriesdatabase;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.logging.log4j.Logger;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import au.com.bytecode.opencsv.CSVReader;
import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import timeseriesdatabase.aggregated.AggregationType;
import util.Table;
import util.Util;
import util.Util.FloatRange;

/**
 * Reads config files and inserts meta data into TimeSeriesDatabase
 * @author woellauer
 *
 */
public class ConfigLoader {

	private static final Logger log = Util.log;

	private TimeSeriesDatabase timeseriesdatabase;

	public ConfigLoader(TimeSeriesDatabase timeseriesdatabase) {
		this.timeseriesdatabase = timeseriesdatabase;
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
				if(timeseriesdatabase.generalStationExists(name)) {
					log.warn("general station already exists: "+name);
				} else {
					timeseriesdatabase.insertGeneralStation(new GeneralStation(name));
				}
			}

		} catch (Exception e) {
			log.error(e);
		}		
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
					if(timeseriesdatabase.sensorExists(sensorName)) {
						// log.info("sensor already exists: "+sensorName+" new in "+typeName);
					} else {
						timeseriesdatabase.insertSensor(new Sensor(sensorName));
					}
				}
				//schema[sensorNames.length] = new Attribute("sampleRate",DataType.SHORT);  // TODO: remove "sampleRate"?   //removed !!!
				timeseriesdatabase.insertLoggerType(new LoggerType(typeName, sensorNames,schema));
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
		Map<String,List<StationProperties>> plotIdMap = readStationConfigInternal(configFile);

		for(Entry<String, List<StationProperties>> entryMap:plotIdMap.entrySet()) {
			if(entryMap.getValue().size()!=1) {
				log.error("multiple properties for one station not implemented:\t"+entryMap.getValue());
			} else {
				String plotID = entryMap.getKey();
				String generalStationName = plotID.substring(0, 3);

				LoggerType loggerType = timeseriesdatabase.getLoggerType(entryMap.getValue().get(0).get_logger_type_name()); 
				if(loggerType!=null) {
					Station station = new Station(timeseriesdatabase, generalStationName, plotID, loggerType, entryMap.getValue());
					timeseriesdatabase.insertStation(station);
				} else {
					log.error("logger type not found: "+entryMap.getValue().get(0).get_logger_type_name()+" -> station not created: "+plotID);
				}			

			}
		}	
	}
	
	/**
	 * reads properties of stations
	 * @param configFile
	 */
	static Map<String,List<StationProperties>> readStationConfigInternal(String config_file) {
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

			Map<String,List<StationProperties>> plotidMap = new HashMap<String,List<StationProperties>>();
			int plotidIndex = nameMap.get("PLOTID");
			for(String[] row:values) {
				String plotid = row[plotidIndex];
				List<StationProperties> entries = plotidMap.get(plotid);
				if(entries==null) {
					entries = new ArrayList<StationProperties>(1);
					plotidMap.put(plotid, entries);
				}				

				Map<String,String> valueMap = new HashMap<String, String>();
				for(Entry<String, Integer> mapEntry:nameMap.entrySet()) {

					String value = row[mapEntry.getValue()];
					if(!value.toUpperCase().equals(NAN_TEXT.toUpperCase())) {
						valueMap.put(mapEntry.getKey(), value);
					}					
				}

				entries.add(new StationProperties(valueMap));
			}
			return plotidMap;			
		} catch (Exception e) {
			e.printStackTrace();
			return null;
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
			for(LoggerType loggerType:timeseriesdatabase.getLoggerTypes()) {
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
				for(GeneralStation generalStation:timeseriesdatabase.getGeneralStaions()) {
					String prefix = "000"+generalStation.name;
					if(sectionName.startsWith(prefix)) {
						String general_section = prefix+"xx"+NAME_CONVERSION_HEADER_SOIL_SUFFIX;
						if(sectionName.equals(general_section)) {
							generalStation.sensorNameTranlationMap = Util.readIniSectionMap(section);
						} else if(sectionName.endsWith(NAME_CONVERSION_HEADER_SOIL_SUFFIX)) {
							String plotID = sectionName.substring(3, 8);
							Station station = timeseriesdatabase.getStation(plotID);
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
					Station station = timeseriesdatabase.getStation(plotID);
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
	
	public void calcNearestStations() {
		timeseriesdatabase.updateGeneralStations();
		for(Station station:timeseriesdatabase.getStations()) {
			double[] geoPos = transformCoordinates(station.geoPoslongitude,station.geoPosLatitude);
			List<Object[]> differenceList = new ArrayList<Object[]>();
			List<Station> stationList = timeseriesdatabase.getGeneralStation(station.generalStationName).stationList;
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
	
	public void readLoggerTypeSensorTranslationConfig(String configFile) {		
		String SENSOR_TRANSLATION_HEADER_SUFFIX = "_sensor_translation";
		try {
			Wini ini = new Wini(new File(configFile));
			for(LoggerType loggerType:timeseriesdatabase.getLoggerTypes()) {
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
					if(timeseriesdatabase.generalStationExists(gen)) {
						generalStationName = gen;
					} else {
						log.warn("unknown general station in: "+plotID+"\t"+gen);
					}
				} else {
					log.warn("unknown general station in: "+plotID);
				}



				if(!timeseriesdatabase.generalStationExists(generalStationName)) {// TODO
					log.warn("unknown general station: "+generalStationName);
				}
				/*VirtualPlot virtualplot = virtualplotMap.get(plotID);
				if(virtualplot==null) {
					virtualplot = new VirtualPlot(plotID, generalStationName);
					virtualplotMap.put(plotID, virtualplot);
				} else {
					log.warn("virtual plot already exists: "+plotID);
				}*/
				timeseriesdatabase.insertVirtualPlot(new VirtualPlot(plotID, generalStationName));
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
	
	/**
	 * reads properties of stations and creates Station Objects
	 * @param configFile
	 */
	public void readKiLiStationConfig(String configFile) { //  KiLi
		Map<String, List<StationProperties>> serialNameMap = timeseriesdatabase.readKiLiStationConfigInternal(configFile);
		for(Entry<String, List<StationProperties>> entry:serialNameMap.entrySet()) {
			String serialName = entry.getKey();
			List<StationProperties> propertiesList = entry.getValue();
			if(!timeseriesdatabase.stationExists(serialName)) {
				LoggerType loggerType = null;
				for(StationProperties properties:propertiesList) {
					String newloggerName = timeseriesdatabase.loggerPropertyKiLiToLoggerName(properties.get_logger_type_name());
					if(newloggerName!=null) {
						LoggerType newloggerType = timeseriesdatabase.getLoggerType(newloggerName);
						if(newloggerType!=null) {
							if(loggerType!=null&&loggerType!=newloggerType) {
								log.warn("different logger types defined: "+loggerType+"  "+newloggerType+"   in "+serialName);
							}
							loggerType = newloggerType;
						} else {
							log.warn("loggertype not found: "+newloggerName);
						}
					} else {
						log.warn("no loggertype name");
					}
				}
				if(loggerType!=null) {
					Station station = new Station(timeseriesdatabase,null,serialName,loggerType,propertiesList);
					timeseriesdatabase.insertStation(station);				
					for(StationProperties properties:propertiesList) {
						String virtualPlotID = properties.get_plotid();
						VirtualPlot virtualPlot = timeseriesdatabase.getVirtualPlot(virtualPlotID);
						if(virtualPlot!=null) {
							virtualPlot.addStationEntry(station, properties);
						} else {
							log.warn("virtual plot id not found: "+virtualPlotID);
						}
					}				
				} else {
					log.error("station with no logger type not inserted: "+serialName);
				}				
			} else {
				log.error("serialName already inserted: "+serialName);
			}
		}


		/*Map<String, List<StationProperties>> serialMap = readKiLiStationConfigInternal(configFile);
		for(Entry<String, List<StationProperties>> entry:serialMap.entrySet()) {
			String serial = entry.getKey();
			//Map<String, String> firstProperyMap = entry.getValue().get(0); // !!
			//final String GENERALSTATION_PROPERTY_NAME = "TYPE";
			//String firstGeneralStationName = firstProperyMap.get(GENERALSTATION_PROPERTY_NAME); // not used
			//String firstGeneralStationName = plotIdKiLiToGeneralStationName(firstProperyMap.get("PLOTID"));
			//System.out.println("generalStationName: "+generalStationName+" serial: "+serial);
			if(!stationMap.containsKey(serial)) {
				//System.out.println(serial);
				//String loggerName = loggerPropertyKiLiToLoggerName(entry.getValue().get(0).get("LOGGER"));
				String loggerName = loggerPropertyKiLiToLoggerName(entry.getValue().get(entry.getValue().size()-1).get_logger_type_name());// !! better loggerType match of inventory
				//System.out.println("logger name: "+loggerName);
				LoggerType loggerType = loggerTypeMap.get(loggerName); 
				if(loggerType!=null) {
					//Station station = new Station(this, null, serial,loggerType, entry.getValue().get(0), entry.getValue()); // !!
					Station station = new Station(this, null, serial,loggerType, entry.getValue());
					stationMap.put(serial, station);
					for(StationProperties properties:entry.getValue()) {
						String plotid = properties.get_plotid();
						//String generalStationName = properyMap.get(GENERALSTATION_PROPERTY_NAME);
						VirtualPlot virtualplot = virtualplotMap.get(plotid);
						if(virtualplot!=null) {
							//if(!virtualplot.generalStationName.equals(generalStationName)) {
						//log.warn("different general station names: "+virtualplot.generalStationName+"\t"+generalStationName+" in "+plotid);
					//}

							try {


								virtualplot.addStationEntry(station, properties);
							} catch (Exception e) {
								log.warn("entry not added: "+e);
							}
						} else {
							log.warn("virtual plotid not found: "+plotid+"    "+serial);
						}
					}
				} else {				
					log.error("logger type not found: "+entry.getValue().get(0).get_logger_type_name()+" -> station not created: "+serial);				
				}						
			}
			else {
				log.warn("serial already inserted: "+serial);
			}
		}*/
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
				timeseriesdatabase.insertIgnoreSensorName(name);
			}

		} catch (Exception e) {
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
				Sensor sensor =  timeseriesdatabase.getSensor(entry.name);
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
				Sensor sensor = timeseriesdatabase.getSensor(entry.name);
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
				Sensor sensor = timeseriesdatabase.getSensor(entry.name);
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
	 * reads sensor config for base aggregation: for each sensor the type of aggregation is read
	 * @param configFile
	 */
	public void readBaseAggregationConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("base_aggregation");
			if(section!=null) {
				for(String sensorName:section.keySet()) {
					Sensor sensor = timeseriesdatabase.getSensor(sensorName);
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
						timeseriesdatabase.baseAggregationSensorNameSet.add(sensorName);
					} else {
						log.warn("sensor not found: "+sensorName);
					}
				}
			}
		} catch (IOException e) {
			log.warn(e);
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
				Sensor sensor = timeseriesdatabase.getSensor(name);
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
	
	public void readEmpiricalDiffConfig(String configFile) {
		try {
			Wini ini = new Wini(new File(configFile));
			Section section = ini.get("parameter_empirical_diff");
			if(section!=null) {
				for(String sensorName:section.keySet()) {
					Sensor sensor = timeseriesdatabase.getSensor(sensorName);
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
}
