package timeseriesdatabase.run;

import processinggraph.Base;
import processinggraph.Node_temp;
import processinggraph.NodeGen;
import processinggraph.QueryPlan;
import processinggraph.RawSource;
import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import util.iterator.TimeSeriesIterator;

public class CreateStationCache {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();

		int lastCommit=0;
		int counter=0;
		for(Station station:timeSeriesDatabase.getStations()) {
			TimeSeriesIterator input_iterator = null;
			//TimeSeriesIterator input_iterator = RawSource.create(timeSeriesDatabase, stationName, null).get(null, null);
			if(station.isPlot) {
				NodeGen stationGen = QueryPlan.getStationGen(timeSeriesDatabase, DataQuality.STEP);
				input_iterator = Base.create(timeSeriesDatabase, station.stationID, null, stationGen).get(null, null);
			}
			if(input_iterator!=null&&input_iterator.hasNext()) {
				System.out.println(station.stationID);
				timeSeriesDatabase.cacheStorage.writeNew(station.stationID, input_iterator);
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
