package tsdb.loader.ki;

import static tsdb.util.AssumptionCheck.throwNull;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.TreeMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.catalog.SourceEntry;
import tsdb.loader.ki.type.AbstractLoader;
import tsdb.loader.ki.type.LoaderFactory;
import tsdb.raw.TimestampSeries;
import de.umr.jepc.store.Event;

/**
 * This class contains methods to read time series from input files in "KiLi"-Format and stores data into database.
 * @author woellauer
 *
 */
public class TimeSeriesLoaderKiLi {

	private static final Logger log = LogManager.getLogger();

	private final TsDB tsdb; //not null

	public TimeSeriesLoaderKiLi(TsDB tsdb) {
		throwNull(tsdb);
		this.tsdb = tsdb;
	}
	
	/**
	 * load load directory with directories of files: structure of tsm
	 * @param root
	 */
	public void loadDirectory_with_stations_flat(Path root) {
		log.info("loadDirectory_with_stations_flat:\t"+root);		
		TreeMap<String,Path> ascCollectorMap = new TreeMap<String,Path>();		
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(root);
			for(Path subPath:stream) {
				if(Files.isDirectory(subPath)) {
					loadOneDirectory_structure_kili(subPath, ascCollectorMap);
				} else {
					log.warn("file in root directory: "+subPath);
				}
			}
			stream.close();
		} catch (IOException e) {
			log.error(e);
		}
		loadWithAscCollectorMap(ascCollectorMap);
	}
	
	/**
	 * Collects all kili-Files from one directory and adds them to ascCollectorMap.
	 * @param kiliPath
	 * @param ascCollectorMap
	 */
	public void loadOneDirectory_structure_kili(Path kiliPath, TreeMap<String, Path> ascCollectorMap) {
		try {
			if(Files.exists(kiliPath)) {
				DirectoryStream<Path> stream = Files.newDirectoryStream(kiliPath);
				System.out.println("*** load directory: "+kiliPath+" ***");
				for(Path path:stream) {
					String filename = path.getName(path.getNameCount()-1).toString();
					int ascIndex = filename.indexOf(".asc");
					if(ascIndex!=-1) {						
						String fileKey = filename.substring(0, ascIndex);						
						ascCollectorMap.putIfAbsent(fileKey, path);
					} else {
						log.warn("no asc file: "+filename);
					}
				}
				stream.close();
			} else {
				log.warn("directory not found: "+kiliPath);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public void loadWithAscCollectorMap(TreeMap<String,Path> ascCollectorMap) {	
		for(Path ascPath:ascCollectorMap.values()) {
			System.out.println("asc file: "+ascPath);

			try{
				ASCTimeSeries csvtimeSeries = new ASCTimeSeries(ascPath);

				TimestampSeries timestampSeries = null;

				if(csvtimeSeries.isASCVariant) {
					timestampSeries = csvtimeSeries.readEntriesASCVariant();
				} else {
					timestampSeries = csvtimeSeries.readEntries();
				}				


				long intervalStart = csvtimeSeries.timestampStart;
				long intervalEnd = csvtimeSeries.timestampEnd;

				if(timestampSeries!=null) {

					if(!timestampSeries.entryList.isEmpty()) {

						Station station = tsdb.getStation(csvtimeSeries.serialnumber);
						if(station!=null) {									

							String[] translatedInputSchema = new String[csvtimeSeries.parameterNames.length];
							for(int i=0;i<csvtimeSeries.parameterNames.length;i++) {
								translatedInputSchema[i] = station.translateInputSensorName(csvtimeSeries.parameterNames[i], false);
							}

							//Map<String, Integer> schemaMap = Util.stringArrayToMap(translatedInputSchema,true);

							StationProperties properties = station.getProperties(intervalStart, intervalEnd);

							if(properties!=null) {

								insertOneFile(csvtimeSeries,station,properties,translatedInputSchema,timestampSeries);

							} else {
								log.warn("no properties found in "+csvtimeSeries.serialnumber+"   "+TimeConverter.oleMinutesToText(intervalStart)+" - "+TimeConverter.oleMinutesToText(intervalEnd));
							}									
						} else {
							log.error("station not found: "+csvtimeSeries.serialnumber+" in "+ascPath);
						}
					} else {
						log.warn("timestampseries is empty");
					}
				} else {
					log.error("no timestampseries: "+csvtimeSeries.filename);
				}
				csvtimeSeries.close();
			} catch(Exception e) {
				log.error(e+" in "+ascPath);
			}
		}		
	}
	
	/**
	 * inserts data of one files to database. Schema is translated to database schema
	 * @param csvtimeSeries
	 * @param station
	 * @param properties
	 * @param translatedInputSchema
	 * @param timestampSeries
	 */
	public void insertOneFile(ASCTimeSeries csvtimeSeries, Station station, StationProperties properties, String[] translatedInputSchema, TimestampSeries timestampSeries) {
		if(station.loggerType.typeName.equals("tfi")) {
			return;  // !!! tfi should not be loaded from this format !!!
		}

		AbstractLoader loader = LoaderFactory.createLoader(station.loggerType.typeName, translatedInputSchema, properties, csvtimeSeries);
		if(loader!=null) {
			List<Event> eventList = loader.load(station, station.loggerType.sensorNames, timestampSeries);			
			if(eventList!=null) {
				tsdb.streamStorage.insertEventList(csvtimeSeries.serialnumber, eventList, csvtimeSeries.timestampStart, csvtimeSeries.timestampEnd, station.loggerType.sensorNames);
				String[] resultSchema = loader.getResultSchema();				
				tsdb.sourceCatalog.insert(new SourceEntry(csvtimeSeries.filename,csvtimeSeries.serialnumber,csvtimeSeries.timestampStart, csvtimeSeries.timestampEnd,eventList.size(),csvtimeSeries.parameterNames, resultSchema, csvtimeSeries.timeStep));
			} else {
				log.warn("no events inserted: "+csvtimeSeries.filename);
			}			
		} else {
			log.warn("no loader found for logger type: "+station.loggerType.typeName);
		}		
	}

	
	
	/**
	 * specific to KiLi:
	 * read files contained in subfolders in KiLi folder tree
	 * @param kiliPath
	 */
	@Deprecated
	public void loadDirectoryOfAllExploratories_structure_kili(Path kiliPath) {		
		TreeMap<String,Path> ascCollectorMap = new TreeMap<String,Path>();		
		log.info("loadDirectoryOfAllExploratories_structure_kili:\t"+kiliPath);
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(kiliPath);
			for(Path path:stream) {
				if(Files.isDirectory(path)) {
					DirectoryStream<Path> subStream = Files.newDirectoryStream(path,"ra*");
					for(Path subPath:subStream) {
						loadOneDirectory_structure_kili(subPath, ascCollectorMap);
					}
					subStream.close();
				}
			}
			stream.close();
		} catch (IOException e) {
			log.error(e);
		}
		loadWithAscCollectorMap(ascCollectorMap);		
	}	
}
