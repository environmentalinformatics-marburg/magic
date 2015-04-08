package tsdb.run;

import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.ki.AscParser;
import tsdb.util.AssumptionCheck;
import tsdb.util.DataEntry;
import tsdb.util.iterator.TimestampSeries;

public class ImportSaOwn {
	private static final Logger log = LogManager.getLogger();

	private final TsDB tsdb;

	public static void main(String[] args) {
		try(TsDB tsdb = TsDBFactory.createDefault()) {		
			Path rootPath = Paths.get("C:/timeseriesdatabase_source/sa_own");			
			ImportSaOwn importSaOwn = new ImportSaOwn(tsdb);			
			importSaOwn.load(rootPath);
		} catch(Exception e) {
			log.error(e);
		}
	}

	public ImportSaOwn(TsDB tsdb) {
		AssumptionCheck.throwNull(tsdb);
		this.tsdb = tsdb;
	}
	
	public void load(String rootPath) {
		load(Paths.get(rootPath));
	}


	public void load(Path rootPath) {
		loadFiles(rootPath);
		loadSubDirs(rootPath);
	}

	public void loadSubDirs(Path rootPath) {
		try(DirectoryStream<Path> rootStream = Files.newDirectoryStream(rootPath)) {
			for(Path sub:rootStream) {
				if(Files.isDirectory(sub)) {
					//log.info("dir "+sub);
					load(sub);
				}

			}
		} catch (Exception e) {
			log.error(e);
		}
	}

	public void loadFiles(Path rootPath) {
		try(DirectoryStream<Path> rootStream = Files.newDirectoryStream(rootPath)) {
			for(Path sub:rootStream) {
				if(!Files.isDirectory(sub)) {
					//log.info("file "+sub);
					loadFile(sub);
				}

			}
		} catch (Exception e) {
			log.error(e);
		}		
	}

	public void loadFile(Path filePath) {
		try {
			//log.info("load file "+filePath);
			TimestampSeries timestampseries = AscParser.parse(filePath);
			if(timestampseries==null) {
				log.error("timestampseries null");
				return;
			}
			Station station = tsdb.getStation(timestampseries.name);
			if(station==null) {
				log.error("station not found "+timestampseries.name);
				return;
			}
			//log.info(timestampseries);

			HashMap<String,String> translationMap = new HashMap<String, String>();
			translationMap.put("Temperature", "Ta_200");			
			translationMap.put("rel.Humidity", "rH_200");
			translationMap.put("DecagonECH2O", "DecagonECH2O");
			translationMap.put("Impulses", "P_RT_NRT");

			translationMap.put("Temperatur", "Ta_200");
			translationMap.put("rel.Feuchte", "rH_200");
			translationMap.put("Impulse", "P_RT_NRT");

			for(String sensorName:timestampseries.sensorNames) {
				if(translationMap.containsKey(sensorName)) {
					String targetName = translationMap.get(sensorName);
					if(targetName!=null) {
						DataEntry[] data = timestampseries.toDataEntyArray(sensorName);
						if(data!=null&&data.length>0) {
							//System.out.println("insert in station "+stationName+" sensor "+sensorName+"  elements "+data.length);
							//streamdb.insertSensorData(stationName, sensorName, data);
							//log.info("insert in station "+timestampseries.name+" sensor "+targetName+"  elements "+data.length);
							tsdb.streamStorage.insertDataEntyArray(timestampseries.name, targetName, data);
						}
					}



				} else {
					log.info("sensor not found "+sensorName);
				}

			}



			//log.info(timestampseries);



		} catch (Exception e) {
			log.error(e);
		}
	}

}
