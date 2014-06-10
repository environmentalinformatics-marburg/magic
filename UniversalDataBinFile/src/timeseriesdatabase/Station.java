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
	
	public final String stationID;
	
	private Storage storage;
	
	//SensorID -> Sensor
	public Map<String,Sensor> sensorMap;
	
	public Map<String,String> propertyMap;
	
	public Station(String stationID, Storage storage, Map<String,String> propertyMap) {
		this.stationID = stationID;
		this.sensorMap = new HashMap<String, Sensor>();
		this.storage = storage;
		this.propertyMap = propertyMap;
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
		UniversalDataBinFile udbFile = new UniversalDataBinFile(filename.toString());
		
		TimeSeries timeSeries = udbFile.getTimeSeries();
		
		for(int s=0;s<timeSeries.header.length;s++) {
			String sensorID = nameToID(stationID,timeSeries.header[s].name);
			
			Sensor sensor = sensorMap.get(sensorID);
			if(sensor==null) {
				createSensor(sensorID);
				sensor = sensorMap.get(sensorID);
			}
			sensor.loadTimeSeries(timeSeries.time, timeSeries.data[s]);
		}
		
		/*
		
		SensorData s = udbFile.getConsolidatedSensorData();
		
		int sensorCount = s.getSensorCount();
		for(int i=0;i<sensorCount;i++) {
			dat_decode.Sensor sensorData = s.getSensor(i);
			String sensorID = nameToID(stationID,sensorData.getSensorName());
			Sensor sensor = sensorMap.get(sensorID);
			if(sensor==null) {
				createSensor(sensorID);
				sensor = sensorMap.get(sensorID);
			}
			if(sensor==null) {
				log.error("sensor null");
			}
			sensor.loadTimeSeries(sensorData.getFirstEntryTimeOleMinutes(), sensorData.getTimeStepMinutes(), sensorData.getData());

			//storage.insertTimeSeries(sensorSerial, sensor.getData(), sensor.getFirstEntryTimeOleMinutes(), sensor.getTimeStepMinutes());
		}
		
		
		if(s!=null) {
			log.trace("UDBFile:\t"+filename+"\t\tstationSerial:\t"+stationID+"\t\t"+s.getSensor(0).getFirstDateTime()+"\t-\t"+s.getSensor(0).getLastDateTime());
		} else {
			log.warn(filename+" not read");
		}
		
		*/
		
		
		
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

}
