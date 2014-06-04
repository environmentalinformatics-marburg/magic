package structure;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import structure.Storage.DataStorage;
import dat_decode.SensorData;
import dat_decode.UniversalDataBinFile;

public class Database {
	
	private static final Logger log = LogManager.getLogger("general");
	
	private Storage storage;
	private Map<String,Station> stationMap;
	
	public Database() {
		storage = new Storage(10);
		stationMap = new HashMap<String, Station>();
	}
	
	public void insertStaion(Station station) {
		stationMap.put(station.stationID, station);
	}
		
	
	public void loadDirectoryOfOneExploratory(Path rootPath) {
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(rootPath);
			for(Path path:stream) {
				log.trace("path: "+path);
				loadDirectoryOfOneStation(path);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	public void loadDirectoryOfOneStation(Path rootPath) {
		log.trace("path:\t\t"+rootPath);
		String stationSerial = rootPath.subpath(rootPath.getNameCount()-1, rootPath.getNameCount()).toString();
		log.trace("stationID:\t"+stationSerial);
		
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(rootPath, x -> x.toString().endsWith(".dat"));
			for(Path path:stream) {
				log.trace("path: "+path);
				loadUDBFile(path, stationSerial);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	public void loadUDBFile(Path path, String stationSerial) throws IOException {
		
		Station station = stationMap.get(stationSerial);
		if(station==null) {
			station = new Station(stationSerial);
			stationMap.put(stationSerial, station);
		}
		
		try {
		UniversalDataBinFile udbFile = new UniversalDataBinFile(path.toString());
		SensorData s = udbFile.getConsolidatedSensorData();
		
		int sensorCount = s.getSensorCount();
		for(int i=0;i<sensorCount;i++) {
			dat_decode.Sensor sensor = s.getSensor(i);
			String sensorSerial = stationSerial+"."+sensor.getSensorName();
			storage.insertTimeSeries(sensorSerial, sensor.getData(), sensor.getFirstEntryTimeOleMinutes(), sensor.getTimeStepMinutes());
		}
		
		
		if(s!=null) {
			log.trace("UDBFile:\t"+path+"\t\tstationSerial:\t"+stationSerial+"\t\t"+s.getSensor(0).getFirstDateTime()+"\t-\t"+s.getSensor(0).getLastDateTime());
		} else {
			log.warn(path+" not read");
		}
		
		
		
		
		
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	public void printInfo() {
		System.out.println();
		System.out.println("database info:");
		System.out.println("stattions:\t"+stationMap.size());
		storage.printInfo();
	}
	
	public Storage getStorage() {
		return storage;
	}

}
