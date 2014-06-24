package usecase;

import java.time.LocalDateTime;

import timeseriesdatabase.BaseTimeSeries;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeries;
import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;

public class UseCaseGapFilling {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		String plotID = "HEG25";
		
		System.out.println("start query...");
		String[] querySensorNames = new String[]{"rH_200"};
		
		LocalDateTime start = LocalDateTime.of(2009,01,01,0,0);
		LocalDateTime end = LocalDateTime.of(2013,01,31,23,59);
		long startTimestamp = TimeConverter.DateTimeToOleMinutes(start);
		long endTimestamp = TimeConverter.DateTimeToOleMinutes(end);
		
		
		//String[] querySensorNames = null;
		
		
		//TimeSeries timeSeriesGapFilled = timeSeriesDatabase.queryBaseAggregatedDataGapFilled(plotID, querySensorNames , null, null);
		
		
		TimeSeries timeSeries = timeSeriesDatabase.queryBaseAggregatedData(plotID, querySensorNames, startTimestamp,endTimestamp);
		

		BaseTimeSeries baseTimeSeries = BaseTimeSeries.toBaseTimeSeries(startTimestamp,endTimestamp,timeSeries);
				
		System.out.println("...end query");
		
		
		System.out.println(baseTimeSeries);
		
		baseTimeSeries.writeToCSV("c:/timeseriesdatabase_output/result.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		
		//timeSeriesGapFilled.writeToCSV("k:/output/result.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);
		System.out.println("...end");
	}

}
