package timeseriesdatabase.run;

import processinggraph.RawSource;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import util.iterator.TimeSeriesIterator;

public class CreateStationCache {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();

		int lastCommit=0;
		int counter=0;
		for(String stationName:timeSeriesDatabase.getStationNames()) {
			TimeSeriesIterator input_iterator = RawSource.create(timeSeriesDatabase, stationName, null).get(null, null);
			if(input_iterator!=null&&input_iterator.hasNext()) {
				System.out.println(stationName);
				timeSeriesDatabase.cacheStorage.writeNew(stationName, input_iterator);
				counter++;
				if(lastCommit+20<counter) {
					System.out.println("commit and compact");
					lastCommit = counter;
					timeSeriesDatabase.cacheStorage.commit_and_compact();
				}
			}
		}

		timeSeriesDatabase.close();

		System.out.println("...end");
	}

}
