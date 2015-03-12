package tsdb;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.net.Socket;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.Profile.Section;
import org.ini4j.Wini;

import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import tsdb.util.Util;

/**
 * Factory for TimeSeriesDatabase
 * @author woellauer
 *
 */
public class TsDBFactory {

	private static final Logger log = LogManager.getLogger();

	private static final String PATH_CONFIG_FILENAME = "tsdb_paths.ini";
	private static final String TSDB_PATH_SECTION = "tsdb_paths"; 


	public static String CONFIG_PATH = "config";
	public static String STORAGE_PATH = "storage";

	public static String SOURCE_BE_TSM_PATH = "source/be_tsm";
	public static String SOURCE_KI_TSM_PATH = "source/ki_tsm";
	public static String SOURCE_KI_TFI_PATH = "source/ki_tfi";
	public static String SOURCE_SA_DAT_PATH = "source/sa_dat";

	public static String WEBCONTENT_PATH = "webcontent";
	public static String WEBDOWNLOAD_PATH = "webDownload";

	public static String OUTPUT_PATH = "output";
	
	public static String WEB_SERVER_PREFIX_BASE_URL = ""; //no prefix
	//private static final String WEB_SERVER_PREFIX_BASE_URL = "/0123456789abcdef"; //example prefix
	
	public static String JUST_ONE_REGION = null;
	//public static String JUST_ONE_REGION = "BE";
	//public static String JUST_ONE_REGION = "KI";
	
	public static boolean WEB_SERVER_LOGIN = false;

	static {
		initPaths();
	}

	private static void initPaths() {
		try {
			Wini ini;
			if(Files.exists(Paths.get(PATH_CONFIG_FILENAME))) {
				log.trace("read from root: "+PATH_CONFIG_FILENAME);
				ini = new Wini(new File(PATH_CONFIG_FILENAME));
			} else if(Files.exists(Paths.get(CONFIG_PATH,PATH_CONFIG_FILENAME))) {
				log.trace("read from config: "+PATH_CONFIG_FILENAME);
				ini = new Wini(new File(CONFIG_PATH,PATH_CONFIG_FILENAME));
			} else {
				log.trace("no "+PATH_CONFIG_FILENAME);
				return;
			}
			Section section = ini.get(TSDB_PATH_SECTION);
			if(section==null) {
				log.warn("no "+TSDB_PATH_SECTION+" section in "+ini.getFile());
				return;
			}
			Map<String, String> pathMap = Util.readIniSectionMap(section);
			if(pathMap.containsKey("CONFIG_PATH")) {
				CONFIG_PATH = pathMap.get("CONFIG_PATH");
			}
			if(pathMap.containsKey("STORAGE_PATH")) {
				STORAGE_PATH = pathMap.get("STORAGE_PATH");
			}
			if(pathMap.containsKey("SOURCE_BE_TSM_PATH")) {
				SOURCE_BE_TSM_PATH = pathMap.get("SOURCE_BE_TSM_PATH");
			}
			if(pathMap.containsKey("SOURCE_KI_TSM_PATH")) {
				SOURCE_KI_TSM_PATH = pathMap.get("SOURCE_KI_TSM_PATH");
			}
			if(pathMap.containsKey("SOURCE_KI_TFI_PATH")) {
				SOURCE_KI_TFI_PATH = pathMap.get("SOURCE_KI_TFI_PATH");
			}
			if(pathMap.containsKey("SOURCE_SA_DAT_PATH")) {
				SOURCE_SA_DAT_PATH = pathMap.get("SOURCE_SA_DAT_PATH");
			}
			if(pathMap.containsKey("WEBCONTENT_PATH")) {
				WEBCONTENT_PATH = pathMap.get("WEBCONTENT_PATH");
			}
			if(pathMap.containsKey("WEBDOWNLOAD_PATH")) {
				WEBDOWNLOAD_PATH = pathMap.get("WEBDOWNLOAD_PATH");
			}
			if(pathMap.containsKey("OUTPUT_PATH")) {
				OUTPUT_PATH = pathMap.get("OUTPUT_PATH");
			}
			//WEB_SERVER_PREFIX_BASE_URL
			if(pathMap.containsKey("WEB_SERVER_PREFIX_BASE_URL")) {
				WEB_SERVER_PREFIX_BASE_URL = pathMap.get("WEB_SERVER_PREFIX_BASE_URL");
			}
			if(pathMap.containsKey("JUST_ONE_REGION")) {
				JUST_ONE_REGION = pathMap.get("JUST_ONE_REGION");
			}
			if(pathMap.containsKey("WEB_SERVER_LOGIN")) {
				
				if(pathMap.get("WEB_SERVER_LOGIN").toLowerCase().trim().equals("true")) {
					WEB_SERVER_LOGIN = true;
				} else if(pathMap.get("WEB_SERVER_LOGIN").toLowerCase().trim().equals("false")) {
					WEB_SERVER_LOGIN = false;
				} else {
					log.warn("ini config value for WEB_SERVER_LOGIN unknown: "+pathMap.get("WEB_SERVER_LOGIN"));
					WEB_SERVER_LOGIN = false;
				}
				
				
				
			}			
		} catch (IOException e) {
			e.printStackTrace();
		}		
	}

	public static ServerTsDB createDefaultServer() {
		TsDB tsdb = createDefault();
		ServerTsDB serverTsDB;
		try {
			serverTsDB = new ServerTsDB(tsdb);
			return serverTsDB;
		} catch (RemoteException e) {
			log.error(e);
			return null;
		}
	}

	public static TsDB createDefault() {
		//initPaths();		
		return createDefault(STORAGE_PATH+"/",CONFIG_PATH,STORAGE_PATH+"/",STORAGE_PATH+"/streamdb");
	}

	public static TsDB createDefault(String databaseDirectory,String configPath, String cacheDirectory, String streamdbPathPrefix) {
		String configDirectory = configPath+"/";
		try {
			TsDB tsdb = new TsDB(databaseDirectory,configDirectory+"eventstore_config.properties", cacheDirectory, streamdbPathPrefix);
			ConfigLoader configLoader = new ConfigLoader(tsdb);

			//*** global config start			
			configLoader.readRegionConfig(configDirectory+"region.ini");
			//*** global config end

			//*** BE start
			configLoader.readLoggerSchemaConfig(configDirectory+"be_logger_type_schema.ini"); // BE 2. read schema of logger types and create: logger type objects, sensor objects
			configLoader.readGeneralStationConfig(configDirectory+"be_general_stations.ini"); // BE 1. read list of general stations and create: general station objects
			configLoader.readStationConfig(configDirectory+"be_config_station_inventory.cnf"); // BE 3. read station list, generate general station name and properties and create station objects
			configLoader.readSensorTranslation(configDirectory+"be_sensor_translation.ini");
			//configLoader.readSensorNameTranslationConfig(configDirectory+"be_config_level0050_standards.cnf"); // BE 4. read read input name sensor translation and insert it in existing logger type objects
			configLoader.readStationGeoPositionConfig(configDirectory+"be_station_master.csv"); // BE read and insert geo position and station serial to station objects, add nearest station list to station object
			//*** BE end


			//*** KiLi start
			configLoader.readLoggerSchemaConfig(configDirectory+"ki_logger_type_schema.ini"); // KiLi 2. read schema of logger types and create: logger type objects, sensor objects
			configLoader.readGeneralStationConfig(configDirectory+"ki_general_stations.ini"); // KiLi 1. read list of general stations and create: general station objects
			configLoader.readLoggerTypeSensorTranslationConfig(configDirectory+"logger_type_sensor_translation_kili.ini"); // KiLi 3. read read input name sensor translation and insert it in existing logger type objects
			configLoader.readVirtualPlotConfig(configDirectory+"station_master.csv"); // KiLi 4. read plotids and create virtualplot objects
			configLoader.readVirtualPlotElevationConfig(configDirectory+"ki_elevation.csv");
			configLoader.readKiLiStationConfig(configDirectory+"ki_config_station_inventory.cnf"); // KiLi 5. read time interval of stations and insert it in virtualplot objects
			configLoader.readUpdatedPlotGeoPosConfig(configDirectory+"kili_plots_correct_xy.csv");
			configLoader.calcNearestVirtualPlots();
			//*** Kili end
			
			//*** South Africa start			
			configLoader.read_sa_station_inventory(configDirectory+"sa_station_inventory.csv");
			configLoader.calcNearestStations();
			//*** South Africa end

			//*** sensor config	start		
			configLoader.readIgnoreSensorNameConfig(configDirectory+"global_sensor_ignore.ini"); // read and insert sensor names that should be not inserted in database
			configLoader.readSensorPhysicalRangeConfig(configDirectory+"parameter_physical_range.ini"); // read and insert physical range to sensor objects
			configLoader.readSensorStepRangeConfig(configDirectory+"parameter_step_range.ini"); // read and insert step range to sensor objects
			configLoader.readBaseAggregationConfig(configDirectory+"global_sensor_aggregation.ini"); // read and insert type of aggregation to sensor objects
			configLoader.readInterpolationSensorNameConfig(configDirectory+"interpolation_sensors.ini"); // read list of sensor names for interpolation and mark sensor objects
			configLoader.readEmpiricalDiffConfig(configDirectory+"parameter_empirical_diff.ini"); // (TODO change) read empirical max diff and insert it in sensor objects
			//*** sensor config end

			//*** global config start
			configLoader.readSensorDescriptionConfig(configDirectory+"sensor_description.ini");
			configLoader.readSensorUnitConfig(configDirectory+"sensor_unit.ini");
			configLoader.readSensorCategoryConfig(configDirectory+"sensor_category.ini");
			//*** global config end

			tsdb.createPlotMap();

			//timeSeriesDatabase.readKiLiStationGeoPositionConfig(configDirectory+"station_master.csv");

			tsdb.updateGeneralStations(); //TODO later remove!


			return tsdb;		
		} catch (Exception e) {
			e.printStackTrace();
			log.error("create TimeSeriesDatabase"+e);
			return null;
		}		
	}

	public static String get_CSV_output_directory() {		
		return OUTPUT_PATH+"/";
	}

	public static final String RMI_SERVER_NAME = "ServerTsDB";
	public static final int RMI_REGISTRY_PORT = 16825;
	public static final int RMI_SERVER_PORT = 16826;
	public static String RMI_DEFAULT_SERVER_IP = "192.168.191.183";

	public static String get_rmi_server_url() {
		return get_rmi_server_url(RMI_DEFAULT_SERVER_IP);
	}

	public static String get_rmi_server_url(String server_ip) {
		return "rmi://"+server_ip+':'+RMI_SERVER_PORT+'/'+RMI_SERVER_NAME;
	}

	public static RemoteTsDB createRemoteConnection() {
		return createRemoteConnection(RMI_DEFAULT_SERVER_IP);
	}

	public static RemoteTsDB createRemoteConnection(String server_ip) {
		try {
			System.out.println("get registry from: "+server_ip+":"+RMI_REGISTRY_PORT);
			Registry registry = LocateRegistry.getRegistry(server_ip,RMI_REGISTRY_PORT);
			System.out.println(registry.getClass());
			String serverUrl = null;
			try {
				try{

					log.info("available RMI servers: "+Util.arrayToString(registry.list()));

					String hostname = InetAddress.getLocalHost().getHostAddress();
					log.info("IP of this client: " + hostname);
				} catch(Exception e) {
					log.warn(e);
				}

				
				for(String entry:registry.list()) {
					//if(entry.endsWith(RMI_SERVER_NAME)) {
					if(entry.equals(RMI_SERVER_NAME)) {
						if(serverUrl != null) {
							log.warn("multiple server entries: "+serverUrl+"   "+entry);
						}
						serverUrl = entry;
					}
				}


			} catch (Exception e) {
				log.warn(e);
			}
			if(serverUrl==null) {
				serverUrl = get_rmi_server_url(server_ip);
			}
			log.info("conntect to "+serverUrl+ " with registry at "+server_ip+":"+RMI_REGISTRY_PORT);
			RemoteTsDB remoteTsDB = (RemoteTsDB) registry.lookup(serverUrl);
			log.info("connected remoteTsDB: "+remoteTsDB.toString());
			return remoteTsDB;
		} catch (Exception e) {
			log.error(e);
			return null;
		}	
	}

	public static String getLocalIP() {
		try {
			Socket socket = new Socket("uni-marburg.de", 80, null, 0);
			String ip = socket.getLocalAddress().getCanonicalHostName();
			socket.close();
			return ip;			
		} catch (IOException e) {
			log.error(e);
			return null;
		}
	}

}
