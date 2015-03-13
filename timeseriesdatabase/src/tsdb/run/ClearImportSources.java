package tsdb.run;

import java.nio.file.Paths;
import java.time.LocalDateTime;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.be.TimeSeriesLoaderBE;
import tsdb.loader.ki.TimeSeriesLoaderKiLi_manual_tfi;
import tsdb.loader.ki.TimeSeriesLoaderKiLi;
import tsdb.util.TimeConverter;

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
		
		long timeStartBE = 0;
		long timeEndBE = 0;
		long timeStartKI = 0;
		long timeEndKI = 0;
		long timeStartKItfi = 0;
		long timeEndKItfi = 0;
		long timeStartSA = 0;
		long timeEndSA = 0;

		System.gc();
		if(TsDBFactory.JUST_ONE_REGION==null||TsDBFactory.JUST_ONE_REGION.toUpperCase().equals("BE")) { //*** BE
			log.info("import BE tsm");
			log.info("from "+TsDBFactory.SOURCE_BE_TSM_PATH);
			timeStartBE = System.currentTimeMillis();
			long minTimestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2008, 01, 01, 00, 00));
			TimeSeriesLoaderBE timeseriesloaderBE = new TimeSeriesLoaderBE(tsdb, minTimestamp);
			timeseriesloaderBE.loadDirectory_with_stations_flat(Paths.get(TsDBFactory.SOURCE_BE_TSM_PATH));
			timeEndBE = System.currentTimeMillis();
			System.gc();
		}
		if(TsDBFactory.JUST_ONE_REGION==null||TsDBFactory.JUST_ONE_REGION.toUpperCase().equals("KI")) { //*** KI
			log.info("import KI tsm");
			log.info("from "+TsDBFactory.SOURCE_KI_TSM_PATH);
			timeStartKI = System.currentTimeMillis();
			TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(tsdb);
			timeseriesloaderKiLi.loadDirectory_with_stations_flat(Paths.get(TsDBFactory.SOURCE_KI_TSM_PATH),true);
			timeEndKI = System.currentTimeMillis();
			System.gc();
			log.info("import KI tfi");
			log.info("from "+TsDBFactory.SOURCE_KI_TFI_PATH);
			timeStartKItfi = System.currentTimeMillis();
			TimeSeriesLoaderKiLi_manual_tfi TimeSerieaLoaderKiLi_manual_tfi = new TimeSeriesLoaderKiLi_manual_tfi(tsdb);
			TimeSerieaLoaderKiLi_manual_tfi.loadOneDirectory_structure_kili_tfi(Paths.get(TsDBFactory.SOURCE_KI_TFI_PATH));
			timeEndKItfi = System.currentTimeMillis();
			System.gc();
		}
		if(TsDBFactory.JUST_ONE_REGION==null||TsDBFactory.JUST_ONE_REGION.toUpperCase().equals("SA")) { //*** SA
			log.info("import SA dat");
			log.info("from "+TsDBFactory.SOURCE_SA_DAT_PATH);
			timeStartSA = System.currentTimeMillis();
			new SouthAfricaImport(tsdb);
			timeEndSA = System.currentTimeMillis();
			System.gc();
		}


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

		log.info(msToText(timeStartClear,timeEndClear)+" Clear");
		log.info(msToText(timeStartOpen,timeEndOpen)+" Open");
		log.info(msToText(timeStartBE,timeEndBE)+" BE import");
		log.info(msToText(timeStartKI,timeEndKI)+" KI import");
		log.info(msToText(timeStartKItfi,timeEndKItfi)+" KI tfi import");
		log.info(msToText(timeStartSA,timeEndSA)+" SA import");
		log.info(msToText(timeStartClose,timeEndClose)+" Close");
		log.info(msToText(timeStart,timeEnd)+" total import");
		log.info("");
		log.info(msToText(timeStartAvg,timeEndAvg)+" create averages");
		log.info(msToText(timeStartCompact,timeEndCompact)+" compact streamDB");
	}
	
	private static String msToText(long start, long end) {
		long diff = end-start;
		long h = diff%1000/100;
		long z = diff%100/10;
		long e = diff%10;
		return diff/1000+"."+h+z+e+" s";
	}
}
