package tsdb.run;

import java.nio.file.Paths;
import java.time.LocalDateTime;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.be.TimeSeriesLoaderBE;
import tsdb.loader.ki.TimeSeriesLoaderKiLi_manual_tfi;
import tsdb.loader.ki.TimeSeriesLoaderKiLi;

public class ClearImportSources {
	
	private static final Logger log = LogManager.getLogger();
	
	public static void main(String[] args) {
		long timeStart = System.currentTimeMillis();
		log.info("begin import");
		
		log.info("open database");
		long timeStartClear = System.currentTimeMillis();
		TsDB tsdb = TsDBFactory.createDefault();
		log.info("clear database");
		tsdb.clear();
		tsdb.close();
		long timeEndClear = System.currentTimeMillis();
		
		log.info("reopen database");
		long timeStartOpen = System.currentTimeMillis();
		tsdb = TsDBFactory.createDefault();
		long timeEndOpen = System.currentTimeMillis();
		TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(tsdb);
		long minTimestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2008, 01, 01, 00, 00));
		TimeSeriesLoaderBE timeseriesloaderBE = new TimeSeriesLoaderBE(tsdb, minTimestamp);
		TimeSeriesLoaderKiLi_manual_tfi TimeSerieaLoaderKiLi_manual_tfi = new TimeSeriesLoaderKiLi_manual_tfi(tsdb);
		
		log.info("register streams");
		tsdb.registerStreams();
		
		System.gc();
		log.info("import BE tsm");
		log.info("from "+TsDBFactory.SOURCE_BE_TSM_PATH);
		long timeStartBE = System.currentTimeMillis();
		timeseriesloaderBE.loadDirectory_with_stations_flat(Paths.get(TsDBFactory.SOURCE_BE_TSM_PATH));
		long timeEndBE = System.currentTimeMillis();
		System.gc();
		log.info("import KI tsm");
		log.info("from "+TsDBFactory.SOURCE_BE_TSM_PATH);
		long timeStartKI = System.currentTimeMillis();
		timeseriesloaderKiLi.loadDirectory_with_stations_flat(Paths.get(TsDBFactory.SOURCE_KI_TSM_PATH),true);
		long timeEndKI = System.currentTimeMillis();
		System.gc();
		log.info("import KI tfi");
		log.info("from "+TsDBFactory.SOURCE_KI_TFI_PATH);
		long timeStartKItfi = System.currentTimeMillis();
		TimeSerieaLoaderKiLi_manual_tfi.loadOneDirectory_structure_kili_tfi(Paths.get(TsDBFactory.SOURCE_KI_TFI_PATH));
		long timeEndKItfi = System.currentTimeMillis();
		System.gc();

		long timeStartClose = System.currentTimeMillis();
		tsdb.close();
		long timeEndClose = System.currentTimeMillis();
		long timeEnd = System.currentTimeMillis();
		
		log.info("end import");
		
		long timeStartAvg = System.currentTimeMillis();
		CreateStationGroupAverageCache.main(null);
		long timeEndAvg = System.currentTimeMillis();
		
		long timeStartCompact = System.currentTimeMillis();
		RunCompact.main(null);
		long timeEndCompact = System.currentTimeMillis();
		
		log.info((timeEndClear-timeStartClear)/1000+" s Clear");
		log.info((timeEndOpen-timeStartOpen)/1000+" s Open");
		log.info((timeEndBE-timeStartBE)/1000+" s BE import");
		log.info((timeEndKI-timeStartKI)/1000+" s KI import");
		log.info((timeEndKItfi-timeStartKItfi)/1000+" s KI tfi import");
		log.info((timeEndClose-timeStartClose)/1000+" s Close");
		log.info((timeEnd-timeStart)/1000+" s total import");
		log.info("");
		log.info((timeEndAvg-timeStartAvg)/1000+" s create averages");
		log.info((timeEndCompact-timeStartCompact)/1000+" s compact streamDB");
		
		//System.exit(0);
	}
}
