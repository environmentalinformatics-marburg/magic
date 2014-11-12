package tsdb.run;

import java.nio.file.Paths;
import java.time.LocalDateTime;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.be.TimeSeriesLoaderBE;
import tsdb.loader.ki.TimeSerieaLoaderKiLi_manual_tfi;
import tsdb.loader.ki.TimeSeriesLoaderKiLi;

public class ClearImportSources {
	
	private static final Logger log = LogManager.getLogger();
	
	public static void main(String[] args) {
		log.info("begin import");
		
		log.info("open database");
		TsDB tsdb = TsDBFactory.createDefault();
		log.info("clear database");
		tsdb.clear();
		tsdb.close();
		
		log.info("reopen database");
		tsdb = TsDBFactory.createDefault();
		TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(tsdb);
		long minTimestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2008, 01, 01, 00, 00));
		TimeSeriesLoaderBE timeseriesloaderBE = new TimeSeriesLoaderBE(tsdb, minTimestamp);
		TimeSerieaLoaderKiLi_manual_tfi TimeSerieaLoaderKiLi_manual_tfi = new TimeSerieaLoaderKiLi_manual_tfi(tsdb);
		
		log.info("register streams");
		tsdb.registerStreams();
		
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
		TimeSerieaLoaderKiLi_manual_tfi.loadOneDirectory_structure_kili_tfi(Paths.get(TsDBFactory.SOURCE_KILI_TFI_PATH));
		System.gc();

		tsdb.close();
		log.info("end import");
		System.exit(0);
	}
}
