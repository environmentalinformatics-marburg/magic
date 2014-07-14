package usecase;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.TimeSeries;
import util.CSV;
import util.CSVTimeType;

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
		
		
		TimeSeries timeSeries = TimeSeries.create(qp.query_continuous_base_aggregated(plotID, querySchema, start, end, DataQuality.EMPIRICAL));
		
		TimeSeries timeSeriesGapFilled = TimeSeries.create(qp.query_base_aggregated_interpolated(plotID, querySchema, start, end, DataQuality.EMPIRICAL));
		
		CSV.write(timeSeries,"c:/timeseriesdatabase_output/timeseries.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);
		CSV.write(timeSeriesGapFilled,"c:/timeseriesdatabase_output/timeSeriesGapFilled.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		
		System.out.println("...end");
	}

}
