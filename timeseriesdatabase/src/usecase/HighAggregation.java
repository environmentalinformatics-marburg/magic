package usecase;

import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;

public class HighAggregation {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		String plotID = "HEG01";
		String[] querySchema = new String[]{"Ta_200"};
		//String[] sensorNames = new String[]{"rH_200"};		
		Long start = null;
		Long end = null;
		
		
		TimestampSeries timeSeries = timeSeriesDatabase.queryAggregatedTimeSeries(plotID, querySchema, start, end, null, true, true, true);
		
		timeSeries.writeToCSV("c:/timeseriesdatabase_output/high_aggregated.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);

		
		
		System.out.println("...end");
	}

}
