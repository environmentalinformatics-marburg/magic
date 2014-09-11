package tsdb.usecase;

import java.time.LocalDateTime;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.QueryProcessor;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import tsdb.util.iterator.TsIterator;

public class UseCaseQueryAlbedo {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		//2013-12-18T08:10,0.704
		long start = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2013,12,18,0,0));
		long end = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2013,12,18,23,59));
		
		//TimeSeriesIterator it = qp.query_raw("HEG24", new String[]{"Albedo"}, null, null);
		//TimeSeriesIterator it = qp.query_raw_with_bad_quality_removed("HEG24", new String[]{"Albedo"}, start, end, DataQuality.EMPIRICAL);
		//TimeSeriesIterator it = qp.query_base_aggregated("HEG24", new String[]{"Albedo"}, null, null, DataQuality.NO);
		TsIterator it = qp.query_aggregated("HEG24", new String[]{"Albedo"}, null, null, DataQuality.EMPIRICAL, AggregationInterval.DAY);
		
		CSV.write(it, "c:/timeseriesdatabase_output/Albedo.CSV", ",", "Na", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		
		System.out.println("...end");
	}

}
