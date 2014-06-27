package usecase;

import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.raw.TimestampSeriesEntry;
import util.SchemaIterator;

public class UseCaseStepCheck {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		SchemaIterator<TimestampSeriesEntry> it = timeSeriesDatabase.queryTesting("HEG01",null,null,null,true,true,true);
		
		while(it.hasNext()) {
			TimestampSeriesEntry e = it.next();
			System.out.println(e.timestamp);
		}
		
		
		System.out.println("...end");
	}

}
