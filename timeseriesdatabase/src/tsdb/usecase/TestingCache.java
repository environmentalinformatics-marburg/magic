package tsdb.usecase;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.QueryProcessor;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.graph.CacheBase;
import tsdb.graph.Node;
import tsdb.graph.QueryPlan;
import tsdb.util.iterator.TsIterator;

public class TestingCache {

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB tsdb = TsDBFactory.createDefault();
		/*QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		String plotID = "HEG20";
		String[] querySchema = new String[]{"Ta_200"};
		Long queryStart = null;
		Long queryEnd = null;
		AggregationInterval aggregationInterval = AggregationInterval.DAY;
		DataQuality dataQuality = DataQuality.NO;
		boolean useInterpolation = true;

		TsIterator it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, useInterpolation);
		timeSeriesDatabase.cacheStorage.writeNew("myStream", it);
		
		//TsIterator iterator = timeSeriesDatabase.cacheStorage.query("myStream", null, null);
		TsIterator iterator = timeSeriesDatabase.cacheStorage.query("AEG", null, null);
		while(iterator.hasNext()) {
			System.out.println(iterator.next());
		}*/


		tsdb.cacheStorage.printInfo();
		
		//Node node = QueryPlan.cache(tsdb, "AEG", null, AggregationInterval.HOUR);
		Node node = CacheBase.create(tsdb, "AEG", null);
		TsIterator it = node.get(null, null);
		//TsIterator it = tsdb.cacheStorage.query("AEG", null, null);
		it.writeConsole();

		System.out.println("...end");
	}

}
