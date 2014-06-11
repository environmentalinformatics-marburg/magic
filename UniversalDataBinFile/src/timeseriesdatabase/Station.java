package timeseriesdatabase; 

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;













import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import dat_decode.DataRow;
import dat_decode.SensorData;
import dat_decode.TimeSeries;
import dat_decode.UniversalDataBinFile;


public class Station {
	
	private static final Logger log = LogManager.getLogger("general");
	
	public Database datebase;
	
	public final String stationID;
	
	public String generalStationName;
	
	private Storage storage;
	
	//SensorID -> Sensor
	public Map<String,Sensor> sensorMap;
	
	//propery name -> value
	public Map<String,String> propertyMap;
	
	public Map<String,String> sensorNameMap;
	
	public Station(Database database, String generalStationName, String stationID, Storage storage, Map<String,String> propertyMap) {
		this.generalStationName = generalStationName;
		this.stationID = stationID;
		this.sensorMap = new HashMap<String, Sensor>();
		this.storage = storage;
		this.propertyMap = propertyMap;
		this.datebase = database;
		this.sensorNameMap = new HashMap<String, String>();
	}
	
	public void setSensorNameMap(Map<String,String> sensorNameMap) {
		this.sensorNameMap = sensorNameMap;
	}
	
	public void loadDirectoryOfOneStation(Path stationPath) {
		log.info("load station:\t"+stationPath+"\tstationID:\t"+stationID);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(stationPath, x -> x.toString().endsWith(".dat"));
			for(Path path:stream) {
				loadUDBFFile(path, stationID);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	public void loadUDBFFile(Path filename, String stationID) throws IOException {
		log.trace("load UDBF file:\t"+filename+"\tstationID:\t"+stationID);
		try {
			
			String loggerTypeName = propertyMap.get("LOGGER");
			
			timeseriesdatabase.Logger logger = datebase.getLogger(loggerTypeName);
			
			if(logger!=null) {
			
			UniversalDataBinFile udbFile = new UniversalDataBinFile(filename.toString());

			TimeSeries timeSeries = udbFile.getTimeSeries();

			for(int s=0;s<timeSeries.header.length;s++) {
				String rawSensorName = timeSeries.header[s].name;
				//String nomalizedName = logger.getNormalizedName(rawSensorName);
				
				String nomalizedName = getNormalizedName(rawSensorName);

				if(nomalizedName!=null) {
					
					String sensorID = nameToID(stationID,nomalizedName);

					Sensor sensor = sensorMap.get(sensorID);
					if(sensor==null) {
						createSensor(sensorID);
						sensor = sensorMap.get(sensorID);
					}
					sensor.loadTimeSeries(timeSeries.time, timeSeries.data[s]);
				} else {
					log.warn("name not found: "+rawSensorName+"\tin station:\t"+stationID+"\twith logger type:\t"+loggerTypeName+"\t"+filename);
				}
			}
			
			} else {
				log.warn("unknown logger type:\t"+loggerTypeName);
			}


		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	
	
	private static String nameToID(String stationName, String sensorName) {
		if(sensorName.contains("/")) {
			sensorName = sensorName.replace('/', '_');
		}
		return stationName+"__"+sensorName;
	}
	
	private void createSensor(String sensorID) {
		log.trace("create sensor:\t"+sensorID);
		if(sensorMap.containsKey(sensorID)) {
			throw new RuntimeException("sensor already exists: "+sensorID);
		}
		Sensor sensor = new Sensor(sensorID, storage);
		sensorMap.put(sensorID, sensor);
		storage.createFloatStream(sensorID);
	}
	
	public Map<String, String> getProperies() {
		return propertyMap;
	}
	
	public String getNormalizedName(String rawSensorName) {
		
		String normalizedName = sensorNameMap.get(rawSensorName);
		if(normalizedName!=null) {
			return normalizedName;
		}
		
		GeneralStation generalStation = datebase.getGeneralStation(generalStationName);
		if(generalStation!=null) {
			normalizedName = generalStation.getNormalizedName(rawSensorName);
			if(normalizedName!=null) {
				return normalizedName;
			}
		}
		
		String loggerTypeName = propertyMap.get("LOGGER");		
		timeseriesdatabase.Logger logger = datebase.getLogger(loggerTypeName);
		normalizedName = logger.getNormalizedName(rawSensorName);
		
		return normalizedName;
	}
	
	public Map<String, Sensor> getSensorMap() {
		return sensorMap;
	}

}
