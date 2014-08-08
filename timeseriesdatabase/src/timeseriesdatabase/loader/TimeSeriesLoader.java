package timeseriesdatabase.loader;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

import org.apache.logging.log4j.Logger;

import de.umr.jepc.store.Event;
import timeseriesdatabase.Station;
import timeseriesdatabase.StationProperties;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.catalog.SourceEntry;
import timeseriesdatabase.raw.ASCTimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.Util;

/**
 * This class contains methods to read time series from input files and stores data into database.
 * @author woellauer
 *
 */
public class TimeSeriesLoader {
	
	protected static final Logger log = Util.log;
	
	protected TimeSeriesDatabase timeseriesdatabase;
	
	public TimeSeriesLoader(TimeSeriesDatabase timeseriesdatabase) {
		this.timeseriesdatabase = timeseriesdatabase;
	}
	
	/**
	 * specific to BE:
	 * read files with root folder
	 * @param rootPath
	 */
	public void loadDirectory_with_stations_structure_two(Path rootPath) {
		log.info("loadDirectory_with_stations_structure_two:\t"+rootPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(rootPath);
			for(Path stationPath:stream) {
				System.out.println(stationPath+"\t");
				String stationID = stationPath.getName(stationPath.getNameCount()-1).toString();				
				if(!timeseriesdatabase.stationExists(stationID)) {
					log.error("station does not exist in database:\t"+stationID);
				} else {				
					Station station = timeseriesdatabase.getStation(stationID);
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


				if(!timeseriesdatabase.stationExists(stationID)) {
					log.error("station does not exist in database:\t"+stationID);
				} else {				
					Station station = timeseriesdatabase.getStation(stationID);
					station.loadDirectoryOfOneStation(stationPath);
				}
			}
		} catch (IOException e) {
			log.error(e);
		}
	}
}
