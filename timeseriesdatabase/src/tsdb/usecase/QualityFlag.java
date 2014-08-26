package tsdb.usecase;

import java.util.List;

import tsdb.DataQuality;
import tsdb.FactoryTsDB;
import tsdb.QueryProcessor;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.iterator.TimeSeriesIterator;

public class QualityFlag {

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = FactoryTsDB.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		String plotID = "HEG20";
		String[] querySchema = new String[]{"Ta_200", "rH_200", "Ta_10"};
		Long queryStart = null;
		Long queryEnd = null;		
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		AggregationInterval aggregationInterval = AggregationInterval.YEAR;
		
		
		//TimeSeriesIterator result_iterator = qp.TestingQualityQuery(plotID, querySchema,  queryStart,  queryEnd, dataQuality);
		//TimeSeriesIterator result_iterator = qp.TestingBaseAggregatadQualityQuery(plotID, querySchema,  queryStart,  queryEnd, dataQuality);
		//TimeSeriesIterator result_iterator = qp.TestingAggregatadQualityQuery(plotID, querySchema,  queryStart,  queryEnd, dataQuality,aggregationInterval);
		TimeSeriesIterator result_iterator = qp.query_base_aggregated_interpolated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		//TimeSeriesIterator result_iterator = qp.TestingInterpolatedAggregatadQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality,aggregationInterval);
		
		//CSV.write(result_iterator, "c:/timeseriesdatabase_output/qualty_flag.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME, true, false);
		//CSV.write(result_iterator, "c:/timeseriesdatabase_output/qualty_counter.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME, false, true );
		
		CSV.write(result_iterator, "c:/timeseriesdatabase_output/qualty_flag.csv", ",", "NA", CSVTimeType.TIMESTAMP_AND_DATETIME, true, false);
		//CSV.write(result_iterator, "c:/timeseriesdatabase_output/qualty_counter.csv", ",", "NA", CSVTimeType.TIMESTAMP_AND_DATETIME, false, true );

		List<ProcessingChainEntry> chain = result_iterator.getProcessingChain();
		
		System.out.println(result_iterator);
		//System.out.println(chain);
		
		System.out.println("...end");

	}

}
