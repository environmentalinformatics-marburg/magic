package tsdb.run;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.FactoryTsDB;
import tsdb.TsDB;
import tsdb.loader.TimeSeriesLoaderBE;
import tsdb.loader.TimeSeriesLoaderKiLi;
import tsdb.util.Util;

/**
 * UseCaseInitDatabase loads source data into an emptied database.
 * @author woellauer
 *
 */
public class InitDatabase {

	private static final Logger log = Util.log;

	public static void main(String[] args) {
		System.out.println("begin...");
		
		// *** workaround for not created database files ... 
		TsDB timeSeriesDatabase = FactoryTsDB.createDefault();
		timeSeriesDatabase.clear();
		/*try {
			Thread.sleep(500);
		} catch (InterruptedException e) {
			log.warn(e);
		}
		System.gc();*/
		// *** ... workaround
		
		timeSeriesDatabase = FactoryTsDB.createDefault();
		TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(timeSeriesDatabase);
		TimeSeriesLoaderBE timeseriesloaderBE = new TimeSeriesLoaderBE(timeSeriesDatabase);
		
		
		
		if(args.length!=2) {
			System.out.println("load from default paths");
		} else {			
			FactoryTsDB.SOURCE_BE_STRUCTURE_ONE_PATH = args[0];
			FactoryTsDB.SOURCE_BE_STRUCTURE_TWO_PATH = args[1];
		}
		System.out.println("load: "+FactoryTsDB.SOURCE_BE_STRUCTURE_ONE_PATH+"\t\t"+FactoryTsDB.SOURCE_BE_STRUCTURE_TWO_PATH);
		
		timeSeriesDatabase.registerStreams();
		
		
		//String kili_basepath = "c:/timeseriesdatabase_data_source_structure_kili_asc_variant/";
		
		timeseriesloaderBE.loadDirectoryOfAllExploratories_structure_one(Paths.get(FactoryTsDB.SOURCE_BE_STRUCTURE_ONE_PATH));
		timeseriesloaderBE.loadDirectory_with_stations_structure_two(Paths.get(FactoryTsDB.SOURCE_BE_STRUCTURE_TWO_PATH));
		timeseriesloaderKiLi.loadDirectoryOfAllExploratories_structure_kili(Paths.get(FactoryTsDB.SOURCE_KILI_PATH));
		
		/*String kili_basepath_short = "c:/timeseriesdatabase_data_source_structure_kili_SHORT/";
		timeSeriesDatabase.loadDirectoryOfAllExploratories_structure_kili(Paths.get(kili_basepath_short));*/
		
		


		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
