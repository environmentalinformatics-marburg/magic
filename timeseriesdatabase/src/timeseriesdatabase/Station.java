package timeseriesdatabase;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Station {
	
	private static final Logger log = LogManager.getLogger("general");
	
	public TimeSeriesDatabase timeSeriesDatabase;
	
	public String plotID;
	
	public Map<String, String> propertyMap;
	
	public Map<String,String> sensorNameTranlationMap;
	
	public Station(TimeSeriesDatabase timeSeriesDatabase, String plotID, Map<String, String> propertyMap) {
		this.timeSeriesDatabase = timeSeriesDatabase;
		this.plotID = plotID;
		this.propertyMap = propertyMap;
		
		sensorNameTranlationMap = new HashMap<String, String>();
		
		System.out.println(propertyMap);
		
		if(!plotID.equals(propertyMap.get("PLOTID"))) {
			log.error("wrong plotID");
		}
		
	}
	
	public LoggerType getLoggerType() {
		LoggerType loggerType = timeSeriesDatabase.loggerTypeMap.get(propertyMap.get("LOGGER")); 
		if(loggerType==null) {
			log.warn("logger type not found: ");
			System.out.println("logger type not found: ");
		}
		return loggerType;
	}

	public void loadDirectoryOfOneStation(Path stationPath) {
		log.info("load station:\t"+stationPath+"\tplotID:\t"+plotID);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(stationPath, x -> x.toString().endsWith(".dat"));
			for(Path path:stream) {
				loadUDBFFile(path);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	public void loadUDBFFile(Path filename) throws IOException {
		log.trace("load UDBF file:\t"+filename+"\tplotID:\t"+plotID);
		
		UniversalDataBinFile udbFile = new UniversalDataBinFile(filename);
		UDBFTimeSeries udbfTimeSeries = udbFile.getUDBFTimeSeries();
		System.out.println(" "+udbfTimeSeries.time.length);
		
		
		/*
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
		}*/
	}	

}
