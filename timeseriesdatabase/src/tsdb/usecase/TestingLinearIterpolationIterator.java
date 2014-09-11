package tsdb.usecase;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.QueryProcessor;
import tsdb.TsDB;
import tsdb.util.Builder;

public class TestingLinearIterpolationIterator {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String plotID = "HEW49";
		String[] querySchema = new String[]{"Ta_200"};
		Long queryStart = null;
		Long queryEnd = null;
		Builder base_aggregated = Builder.continuous_base_aggregated(qp,plotID, querySchema, queryStart, queryEnd, DataQuality.EMPIRICAL);
		
		base_aggregated.writeCSV(CSV_OUTPUT_PATH+"TestingLinearIterpolationIterator_org.csv");
		base_aggregated.linearInterpolate().writeCSV(CSV_OUTPUT_PATH+"TestingLinearIterpolationIterator_result.csv");
		
		
		
		
		System.out.println("...end");
	}

}
