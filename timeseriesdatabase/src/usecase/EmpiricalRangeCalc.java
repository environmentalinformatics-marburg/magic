package usecase;

import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import util.CSV;
import util.TimeSeriesIterator;

public class EmpiricalRangeCalc {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		
		//String plotID = "HEG01";
		//String plotID = "HEG20";
		String plotID = "HEW12";
		//String[] querySchema = new String[]{"Ta_200"};
		String[] querySchema = null;
		Long queryStart = null;
		Long queryEnd = null;
		
		TimeSeriesIterator it = qp.queryRaw(plotID, querySchema, queryStart, queryEnd);
		//TimeSeriesIterator it = qp.queryAggregated(plotID, querySchema, start, end, AggregationInterval.DAY, false, false, false, false);
		CSV.write(it, "c:/timeseriesdatabase_output/empirical_range.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);
	
		
		System.out.println("...end");
	}

}
