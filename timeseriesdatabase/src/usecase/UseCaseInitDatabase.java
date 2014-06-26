package usecase;

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
		//timeSeriesDatabase.loadDirectoryOfOneExploratory(Paths.get("K:/HEG_short"));
		timeSeriesDatabase.loadDirectoryOfAllExploratories(Paths.get("c:/timeseriesdatabase_data_source"));


		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
