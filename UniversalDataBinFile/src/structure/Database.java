package structure;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import dat_decode.SensorData;
import dat_decode.UniversalDataBinFile;

public class Database {
	
	private static final Logger log = LogManager.getLogger("general");
	
	private Storage storage;
	private Map<String,Station> stationMap;
	
	public Database() {
		storage = new Storage();
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
		String stationID = rootPath.subpath(rootPath.getNameCount()-1, rootPath.getNameCount()).toString();
		log.trace("stationID:\t"+stationID);
		
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(rootPath, x -> x.toString().endsWith(".dat"));
			for(Path path:stream) {
				log.trace("path: "+path);
				loadUDBFile(path, stationID);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	public void loadUDBFile(Path path, String stationID) throws IOException {
		try {
		UniversalDataBinFile udbFile = new UniversalDataBinFile(path.toString());
		SensorData s = udbFile.getSensorData();
		
		log.trace("UDBFile:\t"+path+"\t\tstationID:\t"+stationID+"\t\t"+s.getSensor(0).getFirstDateTime()+"\t-\t"+s.getSensor(0).getLastDateTime());
		} catch (Exception e) {
			log.error(e.getMessage());
		}
	}

}
