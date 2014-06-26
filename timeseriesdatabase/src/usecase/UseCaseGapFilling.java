package usecase;

import java.time.LocalDateTime;
import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;

/**
 * use case for gap filled data
 * @author woellauer
 *
 */
public class UseCaseGapFilling {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		//String plotID = "HEG25";
		String plotID = "HEW01";
		
		System.out.println("start query...");
		String[] querySensorNames = new String[]{"Ta_200"};
		
		LocalDateTime start = LocalDateTime.of(2011,06,01,0,0);		
		LocalDateTime end = LocalDateTime.of(2012,06,01,0,0);
		
		//LocalDateTime start = LocalDateTime.of(2010,01,01,0,0);
		//LocalDateTime end = LocalDateTime.of(2012,12,31,23,00);
		//long startTimestamp = TimeConverter.DateTimeToOleMinutes(start);
		//long endTimestamp = TimeConverter.DateTimeToOleMinutes(end);
		Long startTimestamp = null;
		Long endTimestamp = null;
		
		
		//String[] querySensorNames = null;
		
		TimestampSeries timeSeries = timeSeriesDatabase.queryBaseAggregatedData(plotID, querySensorNames , startTimestamp, endTimestamp);
		TimeSeries baseTimeSeries = timeSeriesDatabase.queryBaseAggregatedDataGapFilled(plotID, querySensorNames , startTimestamp, endTimestamp);
		
		
		//TimeSeries timeSeries = timeSeriesDatabase.queryBaseAggregatedData(plotID, querySensorNames, startTimestamp,endTimestamp);
		

		//BaseTimeSeries baseTimeSeries = BaseTimeSeries.toBaseTimeSeries(startTimestamp,endTimestamp,timeSeries);
				
		System.out.println("...end query");
		
		
		System.out.println(baseTimeSeries);
		System.out.println("timeSeries: "+timeSeries);
		TimeSeries convertedTimeSeries = TimeSeries.toBaseTimeSeries(startTimestamp,endTimestamp,timeSeries);
		
		String nanValue = "NaN";
		
		convertedTimeSeries.writeToCSV("c:/timeseriesdatabase_output/result.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);
		baseTimeSeries.writeToCSV("c:/timeseriesdatabase_output/result_gapfilled.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		System.out.println(timeSeriesDatabase.stationMap.get(plotID).nearestStationList);
		String nearPlot = timeSeriesDatabase.stationMap.get(plotID).nearestStationList.get(0).plotID;
		//String nearPlot = "HEG10";
		TimeSeries timeSeriesNear = TimeSeries.toBaseTimeSeries(convertedTimeSeries.getFirstTimestamp(),convertedTimeSeries.getLastTimestamp(),timeSeriesDatabase.queryBaseAggregatedData(nearPlot, querySensorNames , startTimestamp, endTimestamp));
		timeSeriesNear.writeToCSV("c:/timeseriesdatabase_output/result_near.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		
		
		//timeSeriesGapFilled.writeToCSV("k:/output/result.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);
		System.out.println("...end");
	}

}
