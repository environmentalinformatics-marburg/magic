package tsdb.run;

import tsdb.TsDBFactory;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.graph.Base;
import tsdb.graph.NodeGen;
import tsdb.graph.QueryPlan;
import tsdb.util.DataQuality;
import tsdb.util.iterator.TsIterator;

@Deprecated
public class CreateStationCache {

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();

		int lastCommit=0;
		int counter=0;
		for(Station station:timeSeriesDatabase.getStations()) {
			TsIterator input_iterator = null;
			//TimeSeriesIterator input_iterator = RawSource.create(timeSeriesDatabase, stationName, null).get(null, null);
			if(station.isPlot) {
				NodeGen stationGen = QueryPlan.getStationGen(timeSeriesDatabase, DataQuality.STEP);
				input_iterator = Base.of(timeSeriesDatabase, station.stationID, null, stationGen).get(null, null);
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
