package usecase;

import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.TimeSeries;

public class GapFillingDiff {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String plotID = "HEG01";
		String[] querySchema = new String[]{"Ta_200"};
		//String[] sensorNames = new String[]{"rH_200"};		
		Long start = null;
		Long end = null;
		
		
		TimeSeries timeSeries = qp.queryBaseAggregatedTimeSeries(plotID, querySchema, start, end, true, true, true);
		
		TimeSeries timeSeriesGapFilled = qp.queryGapFilledTimeSeries(plotID, querySchema, start, end, true, true, true);
		
		timeSeries.writeToCSV("c:/timeseriesdatabase_output/timeseries.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);
		timeSeriesGapFilled.writeToCSV("c:/timeseriesdatabase_output/timeSeriesGapFilled.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		
		System.out.println("...end");
	}

}
