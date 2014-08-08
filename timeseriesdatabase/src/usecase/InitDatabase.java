package usecase;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.loader.TimeSeriesLoader;
import util.Util;

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
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		timeSeriesDatabase.clear();
		try {
			Thread.sleep(500);
		} catch (InterruptedException e) {
			log.warn(e);
		}
		System.gc();
		// *** ... workaround
		
		timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		TimeSeriesLoader timeseriesloader = new TimeSeriesLoader(timeSeriesDatabase);
		
		String path1 = "c:/timeseriesdatabase_data_source_structure_one";
		String path2 = "c:/timeseriesdatabase_data_source_structure_two";
		
		if(args.length!=2) {
			System.out.println("load from default paths");
		} else {			
			path1 = args[0];
			path2 = args[1];
		}
		System.out.println("load: "+path1+"\t\t"+path2);
		
		timeSeriesDatabase.registerStreams();
		
		String kili_basepath = "c:/timeseriesdatabase_data_source_structure_kili/";
		
		//timeseriesloader.loadDirectoryOfAllExploratories_structure_one(Paths.get(path1));
		//timeseriesloader.loadDirectory_with_stations_structure_two(Paths.get(path2));
		timeseriesloader.loadDirectoryOfAllExploratories_structure_kili(Paths.get(kili_basepath));
		
		/*String kili_basepath_short = "c:/timeseriesdatabase_data_source_structure_kili_SHORT/";
		timeSeriesDatabase.loadDirectoryOfAllExploratories_structure_kili(Paths.get(kili_basepath_short));*/
		
		


		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
