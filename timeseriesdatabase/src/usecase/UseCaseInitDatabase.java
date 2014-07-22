package usecase;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import util.Util;

/**
 * UseCaseInitDatabase loads source data into an emptied database.
 * @author woellauer
 *
 */
public class UseCaseInitDatabase {

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
		
		timeSeriesDatabase.registerStreams();
		timeSeriesDatabase.loadDirectoryOfAllExploratories_structure_one(Paths.get("c:/timeseriesdatabase_data_source_structure_one"));
		timeSeriesDatabase.loadDirectory_with_stations_structure_two(Paths.get("c:/timeseriesdatabase_data_source_structure_two"));


		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
