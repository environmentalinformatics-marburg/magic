package tsdb.loader.ki;

import static tsdb.util.AssumptionCheck.throwNull;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.catalog.SourceEntry;
import tsdb.raw.TimestampSeries;
import tsdb.raw.iterator.CSVIterator;
import tsdb.util.TimestampInterval;
import tsdb.util.TsSchema;
import de.umr.jepc.store.Event;

public class TimeSeriesLoaderKiLi_manual_tfi {
	
	private static final Logger log = LogManager.getLogger();

	private final TsDB tsdb; //not null

	public TimeSeriesLoaderKiLi_manual_tfi(TsDB tsdb) {
		throwNull(tsdb);
		this.tsdb = tsdb;
	}
	
	/**
	 * load one directory with files of tfi manual measurement files
	 * @param kiliTfiPath
	 */
	public void loadOneDirectory_structure_kili_tfi(Path kiliTfiPath) {		
		try {
			if(Files.exists(kiliTfiPath)) {
				DirectoryStream<Path> stream = Files.newDirectoryStream(kiliTfiPath);
				log.info("load directory of manual tfi files    "+kiliTfiPath);
				for(Path path:stream) {
					String filename = path.getName(path.getNameCount()-1).toString();
					if(filename.endsWith(".csv")) {
						if(filename.indexOf("_tfi")==4) {
							String plotID = filename.substring(0, 4);
							log.info("load plot  "+plotID);
							VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
							if(virtualPlot!=null) {
								loadOneFile_structure_kili_tfi(virtualPlot,path);
							} else {
								log.warn("unknown plotID: "+plotID);
							}
						} else {
							log.warn("no csv tfi file: "+filename);
						}
						//ascCollectorMap.putIfAbsent(fileKey, path);
					} else {
						log.warn("no csv file: "+filename);
					}
				}				
			} else {
				log.warn("directory not found: "+kiliTfiPath);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}		
	}

	/**
	 * load one tfi manual measurement file
	 * @param kiliTfiPath
	 */
	private void loadOneFile_structure_kili_tfi(VirtualPlot virtualPlot, Path path) {		
		CSVIterator input_iterator = CSVIterator.create(path);
		if(input_iterator!=null&&input_iterator.hasNext()) {
			TimestampSeries timestampSeries = input_iterator.toTimestampSeries();
			long start = timestampSeries.getFirstTimestamp();
			long end = timestampSeries.getLastTimestamp();
			String serial = null;
			for(TimestampInterval<StationProperties> interval:virtualPlot.intervalList) {
				if(interval.contains(start, end)) {
					String loggerTypeName = interval.value.get_logger_type_name();
					if(loggerTypeName.equals("tfi")) {
						if(interval.value.get_plotid().equals(virtualPlot.plotID)) {
							if(serial==null) {
								serial = interval.value.get_serial();
							} else {
								log.warn("multiple entries");
							}
						} else {
							log.error("plotIDs not consistent");
						}						
					}
				}
			}
			if(serial!=null) {
				String[] targetSchema = tsdb.getLoggerType("tfi").sensorNames;
				Loader_manual_tfi loader = new Loader_manual_tfi(timestampSeries);
				loader.load(targetSchema);
				List<Event> events = loader.toEvents();
				if(events!=null) {
					tsdb.streamStorage.insertEventList(serial, events, start, end, targetSchema);
					tsdb.sourceCatalog.insert(new SourceEntry(path,serial,start,end,events.size(),timestampSeries.sensorNames, targetSchema, TsSchema.NO_CONSTANT_TIMESTEP));
				} else {
					log.warn("no events inserted: "+path);
				}
			} else {
				log.warn("no serial found for tfi: "+virtualPlot.plotID+"   "+path);
			}
		} else {
			log.warn("empty file: "+path);
		}
	}

}
