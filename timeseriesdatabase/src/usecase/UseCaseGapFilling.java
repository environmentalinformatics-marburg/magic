package usecase;

import java.time.LocalDateTime;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.CSV;
import util.CSVTimeType;
import util.iterator.TimeSeriesIterator;

/**
 * use case for gap filled data
 * @author woellauer
 *
 */
public class UseCaseGapFilling {

	public static void main(String[] args) {
		
		//String nanValue = "0";
		String nanValue = "NaN";
		
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String plotID = "HEW01";
		
		System.out.println("start query...");
		String[] querySensorNames = new String[]{"Ta_200"};
		
		LocalDateTime start = LocalDateTime.of(2011,06,01,0,0);		
		LocalDateTime end = LocalDateTime.of(2012,06,01,0,0);
		long startTimestamp = TimeConverter.DateTimeToOleMinutes(start);
		long endTimestamp = TimeConverter.DateTimeToOleMinutes(end);
		//Long startTimestamp = null;
		//Long endTimestamp = null;
		
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		
		
		TimeSeries result = TimeSeries.create(qp.query_continuous_base_aggregated(plotID, querySensorNames, startTimestamp, endTimestamp, dataQuality));
		TimeSeriesIterator result_interpolated = qp.query_base_aggregated_interpolated(plotID, querySensorNames, startTimestamp, endTimestamp, dataQuality);
		
		System.out.println(result);
		System.out.println(result_interpolated);	
		
		CSV.write(result,"c:/timeseriesdatabase_output/result.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);
		CSV.write(result_interpolated,"c:/timeseriesdatabase_output/result_gapfilled.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		System.out.println(timeSeriesDatabase.getStation(plotID).nearestStationList);
		String nearPlot = timeSeriesDatabase.getStation(plotID).nearestStationList.get(0).plotID;
		TimeSeriesIterator near = qp.query_base_aggregated_interpolated(nearPlot, querySensorNames, result.getFirstTimestamp(), result.getLastTimestamp(), dataQuality);
		
		System.out.println(near);
		
		CSV.write(near,"c:/timeseriesdatabase_output/result_near.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);

		System.out.println("...end");
	}

}
