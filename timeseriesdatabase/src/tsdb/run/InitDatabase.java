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

/**
 * UseCaseInitDatabase loads source data into an emptied database.
 * @author woellauer
 *
 */
public class InitDatabase {
	
	private static final Logger log = LogManager.getLogger();

	public static void main(String[] args) {
		System.out.println("begin...");
		
		// *** workaround for not created database files ... 
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		timeSeriesDatabase.clear();
		/*try {
			Thread.sleep(500);
		} catch (InterruptedException e) {
			log.warn(e);
		}
		System.gc();*/
		// *** ... workaround
		
		timeSeriesDatabase = TsDBFactory.createDefault();
		TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(timeSeriesDatabase);
		long minTimestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2008, 01, 01, 00, 00));
		TimeSeriesLoaderBE timeseriesloaderBE = new TimeSeriesLoaderBE(timeSeriesDatabase, minTimestamp);
		
		
		
		if(args.length!=2) {
			System.out.println("load from default paths");
		} else {			
			TsDBFactory.SOURCE_BE_STRUCTURE_ONE_PATH = args[0];
			TsDBFactory.SOURCE_BE_STRUCTURE_TWO_PATH = args[1];
		}
		System.out.println("load: "+TsDBFactory.SOURCE_BE_STRUCTURE_ONE_PATH+"\t\t"+TsDBFactory.SOURCE_BE_STRUCTURE_TWO_PATH);
		
		timeSeriesDatabase.registerStreams();
		
		
		//String kili_basepath = "c:/timeseriesdatabase_data_source_structure_kili_asc_variant/";
		/*String kili_basepath_short = "c:/timeseriesdatabase_data_source_structure_kili_SHORT/";
		timeSeriesDatabase.loadDirectoryOfAllExploratories_structure_kili(Paths.get(kili_basepath_short));*/
		
		System.gc();
		timeseriesloaderBE.loadDirectoryOfAllExploratories_structure_one(Paths.get(TsDBFactory.SOURCE_BE_STRUCTURE_ONE_PATH));
		System.gc();
		timeseriesloaderBE.loadDirectory_with_stations_structure_two(Paths.get(TsDBFactory.SOURCE_BE_STRUCTURE_TWO_PATH));
		timeseriesloaderBE = null;
		System.gc();
		timeseriesloaderKiLi.loadDirectoryOfAllExploratories_structure_kili(Paths.get(TsDBFactory.SOURCE_KILI_PATH));
		System.gc();
		timeseriesloaderKiLi.loadOneDirectory_structure_kili_tfi(Paths.get(TsDBFactory.SOURCE_KILI_TFI_PATH));
		timeseriesloaderKiLi = null;
		System.gc();
		
		
		


		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
