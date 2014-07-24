package usecase;

import java.util.function.Supplier;

import org.apache.commons.math3.analysis.interpolation.LinearInterpolator;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.iterator.LinearIterpolationIterator;
import util.Builder;
import util.CSV;
import util.iterator.TimeSeriesIterator;

public class TestingLinearIterpolationIterator {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String plotID = "HEW49";
		String[] querySchema = new String[]{"Ta_200"};
		Long queryStart = null;
		Long queryEnd = null;
		Builder base_aggregated = Builder.query_continuous_base_aggregated(qp,plotID, querySchema, queryStart, queryEnd, DataQuality.EMPIRICAL);
		
		base_aggregated.writeCSV(CSV_OUTPUT_PATH+"TestingLinearIterpolationIterator_org.csv");
		base_aggregated.linearInterpolate().writeCSV(CSV_OUTPUT_PATH+"TestingLinearIterpolationIterator_result.csv");
		
		
		System.out.println("...end");
	}

}
