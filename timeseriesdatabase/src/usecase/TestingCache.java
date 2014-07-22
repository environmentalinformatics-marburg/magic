package usecase;

import java.util.Iterator;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.CSV;
import util.CSVTimeType;
import util.iterator.TimeSeriesIterator;

public class TestingCache {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		String plotID = "HEG20";
		String[] querySchema = null;
		Long queryStart = null;
		Long queryEnd = null;
		AggregationInterval aggregationInterval = AggregationInterval.DAY;
		DataQuality dataQuality = DataQuality.NO;
		boolean useInterpolation = true;

		TimeSeriesIterator it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, useInterpolation);
		timeSeriesDatabase.cacheStorage.writeNew("myStream", it);
		
		TimeSeriesIterator iterator = timeSeriesDatabase.cacheStorage.query("myStream", null, null);
		while(iterator.hasNext()) {
			System.out.println(iterator.next());
		}


		timeSeriesDatabase.cacheStorage.printInfo();


		System.out.println("...end");
	}

}
