package usecase;

import timeseriesdatabase.TimeSeries;
import timeseriesdatabase.TimeSeries.CSVTimeType;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;

public class UseCaseGapFilling {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		String plotID = "HEG25";
		
		System.out.println("start query...");
		String[] querySensorNames = new String[]{"rH_200"};
		//String[] querySensorNames = null;
		TimeSeries timeSeriesGapFilled = timeSeriesDatabase.queryBaseAggregatedDataGapFilled(plotID, querySensorNames , null, null);
		System.out.println("...end query");
		
		timeSeriesGapFilled.writeToCSV("k:/output/result.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);
		System.out.println("...end");
	}

}
