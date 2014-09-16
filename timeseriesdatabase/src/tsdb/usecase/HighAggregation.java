package tsdb.usecase;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.QueryProcessor;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import tsdb.util.iterator.TsIterator;

public class HighAggregation {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TsDB tsdb = TsDBFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(tsdb);
		
		
		//String plotID = "HEG01";
		String plotID = "HEG20";
		//String[] querySchema = new String[]{"Ta_200"};
		String[] querySchema = null;
		Long queryStart = null;
		Long queryEnd = null;
		AggregationInterval aggregationInterval = AggregationInterval.DAY;
		DataQuality dataQuality = DataQuality.NO;
		boolean useInterpolation = true;
		
		TsIterator it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, useInterpolation);
		CSV.write(it, "c:/timeseriesdatabase_output/high_aggregated_interpolated.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, false);		
		CSV.write(it, "c:/timeseriesdatabase_output/high_aggregated.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);	
		
		System.out.println("...end");
	}

}
