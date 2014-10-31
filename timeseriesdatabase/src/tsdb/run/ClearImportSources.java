package tsdb.run;

import java.nio.file.Paths;
import java.time.LocalDateTime;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.TimeSeriesLoaderBE;
import tsdb.loader.TimeSeriesLoaderKiLi;

public class ClearImportSources {
	
	private static final Logger log = LogManager.getLogger();
	
	public static void main(String[] args) {
		log.info("begin import");
		
		log.info("open database");
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		log.info("clear database");
		timeSeriesDatabase.clear();
		timeSeriesDatabase.close();
		
		log.info("reopen database");
		timeSeriesDatabase = TsDBFactory.createDefault();
		TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(timeSeriesDatabase);
		long minTimestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2008, 01, 01, 00, 00));
		TimeSeriesLoaderBE timeseriesloaderBE = new TimeSeriesLoaderBE(timeSeriesDatabase, minTimestamp);
		
		log.info("register streams");
		timeSeriesDatabase.registerStreams();
		
		System.gc();
		log.info("import BE from tsm");
		log.info("from "+TsDBFactory.SOURCE_BE_TSM_PATH);
		timeseriesloaderBE.loadDirectory_with_stations_flat(Paths.get(TsDBFactory.SOURCE_BE_TSM_PATH));
		System.gc();
		/*log.info("import KiLi from structure_kili");
		log.info("from "+TsDBFactory.SOURCE_KILI_PATH);
		timeseriesloaderKiLi.loadDirectoryOfAllExploratories_structure_kili(Paths.get(TsDBFactory.SOURCE_KILI_PATH));*/
		timeseriesloaderKiLi.loadDirectory_with_stations_flat(Paths.get(TsDBFactory.SOURCE_KI_TSM_PATH));
		System.gc();
		log.info("import KiLi from structure_kili_tfi");
		log.info("from "+TsDBFactory.SOURCE_KILI_TFI_PATH);
		timeseriesloaderKiLi.loadOneDirectory_structure_kili_tfi(Paths.get(TsDBFactory.SOURCE_KILI_TFI_PATH));
		System.gc();

		timeSeriesDatabase.close();
		log.info("end import");
		System.exit(0);
	}
}
