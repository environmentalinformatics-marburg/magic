package usecase;

import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.CSV;
import util.TimeSeriesIterator;

public class HighAggregation {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String plotID = "HEG01";
		//String[] querySchema = new String[]{"Ta_200"};
		String[] querySchema = null;		
		Long start = null;
		Long end = null;
		
		
		TimeSeriesIterator it = qp.queryAggregated(plotID, querySchema, start, end, AggregationInterval.DAY, true, true, true, false);
		//TimeSeriesIterator it = qp.queryAggregated(plotID, querySchema, start, end, AggregationInterval.DAY, false, false, false, false);
		CSV.write(it, "c:/timeseriesdatabase_output/high_aggregated.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		it = qp.queryAggregated(plotID, querySchema, start, end, AggregationInterval.DAY, true, true, true, true);		
		CSV.write(it, "c:/timeseriesdatabase_output/high_aggregated_interpolated.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);	
		
		System.out.println("...end");
	}

}
