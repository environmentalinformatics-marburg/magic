package databaseloader;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import structure.Station;
import dat_decode.SensorData;
import dat_decode.TimeConverter;
import dat_decode.UniversalDataBinFile;
import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.EventStore;
import de.umr.jepc.util.enums.CapacityUnit;

@Deprecated
public class DatabaseLoader {
	
	private static final Attribute[] FLOAT_ONE_SCHEMA = new Attribute[]{new Attribute("a",DataType.FLOAT)};
	
	private static final Logger log = LogManager.getLogger("general");
	
	private EventStore eventStore;
	private Method method_flushStream;
	private Set<String> streamNames;

	public static void main(String[] args) {
		
		log.trace("start");
		
		Path rootPath = Paths.get("K:/HEG_short");
		//Path rootPath = Paths.get("K:/incoming_ftp/adl-m");
		
		DatabaseLoader databaseLoader = new DatabaseLoader();
		
		databaseLoader.loadDirectoryOfOneExploratory(rootPath);		
		//databaseLoader.loadDirectoryOfAllExploratories(rootPath);
		
		
		databaseLoader.run();
		
		
		
	}
	
	
	
	public DatabaseLoader() {
		try {
			initEventStore();
		} catch (Exception e) {
			log.error(e);
		}
		streamNames = new HashSet<String>();
	}
	
	public void run()  {
		
		Set<String> set = eventStore.getRegisteredStreams();
		System.out.println(set);
		
		log.trace("query...");
		Attribute[] schema = eventStore.getSchema("HG02__LF_200_MAX");

		for(Attribute attribute:schema) {
			System.out.println("attribute: "+attribute);
		}
		Iterator<Event> query = eventStore.query("select * from HG02__LF_200_MAX where tstart>57503490 and tstart<57503730");
		//Iterator<Event> query = eventStore.getHistory("HG02__LF_200_MAX");
		
		while(query.hasNext()) {
			Event e = query.next();
			System.out.println(TimeConverter.oleTimeMinutesToLocalDateTime(e.getTimestamp())+"\t"+e.getPayload()[0]);
		}
		
		
		
		log.trace("...end");
	}
	
	public void initEventStore() throws Exception {
		Class<?> eventStoreClass = Class.forName("de.umr.jepc.store.btree.TimeSplitBTreeEventStore", true, this.getClass().getClassLoader());
		method_flushStream = eventStoreClass.getMethod("flushStream",String.class);
		eventStore = (EventStore) eventStoreClass.newInstance();
		eventStore.open();
		eventStore.clear();
		eventStore.setEventStoreCapacity(1024, CapacityUnit.GB);
	}
	
	public void loadDirectoryOfAllExploratories(Path rootPath) {
		try {
			DirectoryStream<Path> stream = Files.newDirectoryStream(rootPath);
			for(Path path:stream) {
				log.trace("exploratory: "+path);
				loadDirectoryOfOneExploratory(path);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
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
		/*
		Station station = stationMap.get(stationSerial);
		if(station==null) {
			station = new Station(stationSerial);
			stationMap.put(stationSerial, station);
		}
		*/
		try {
		UniversalDataBinFile udbFile = new UniversalDataBinFile(path.toString());
		SensorData s = udbFile.getConsolidatedSensorData();
		
		int sensorCount = s.getSensorCount();
		for(int i=0;i<sensorCount;i++) {
			dat_decode.Sensor sensor = s.getSensor(i);
			String sensorSerial = nameToID(stationSerial,sensor.getSensorName());
			writeToDatabase(sensorSerial,sensor.getFirstEntryTimeOleMinutes(), sensor.getTimeStepMinutes(), sensor.getData());
			//storage.insertTimeSeries(sensorSerial, sensor.getData(), sensor.getFirstEntryTimeOleMinutes(), sensor.getTimeStepMinutes());
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
	
	public void writeToDatabase(String sensorID, long firstTimeStamp, long lastTimeStamp, float[] data) {
		if(!streamNames.contains(sensorID)) {
			log.trace("register stream:\t"+sensorID);
			eventStore.registerStream(sensorID, FLOAT_ONE_SCHEMA);
			streamNames.add(sensorID);
		}
		
		
		log.trace("write to database:\t"+sensorID+"\t\t time stamp: "+firstTimeStamp+"\ttime step: "+lastTimeStamp+"\tcount: "+data.length);
		
		Float[] event = new Float[1];

		for(int i=0;i<data.length;i++) {
			event[0] = data[i];
			eventStore.pushEvent(sensorID, event, firstTimeStamp+(i*30));
			//log.trace("push\t"+sensorID+"\t"+event[0]);
		}

		try {
			method_flushStream.invoke(eventStore, sensorID);
		} catch (IllegalAccessException | IllegalArgumentException
				| InvocationTargetException e1) {
			log.warn("in method_flushStream");
		}

		
		
	}
	
	private static String nameToID(String stationName, String sensorName) {
		if(sensorName.contains("/")) {
			sensorName = sensorName.replace('/', '_');
		}
		return stationName+"__"+sensorName;
	}

}
