package usecase;

import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.catalog.SourceEntry;

public class TestingSourceCatalog {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		for(SourceEntry entry:timeSeriesDatabase.sourceCatalog.getEntriesWithStationName("51071120480")) {
			System.out.println(entry);
		}


	}

}
