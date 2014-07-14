package usecase;

import javafx.scene.chart.PieChart.Data;
import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.CSV;
import util.CSVTimeType;
import util.iterator.TimeSeriesIterator;

public class HighAggregation {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		
		//String plotID = "HEG01";
		String plotID = "HEG20";
		//String[] querySchema = new String[]{"Ta_200"};
		String[] querySchema = null;
		Long queryStart = null;
		Long queryEnd = null;
		AggregationInterval aggregationInterval = AggregationInterval.DAY;
		DataQuality dataQuality = DataQuality.NO;
		boolean useInterpolation = true;
		
		TimeSeriesIterator it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, useInterpolation);
		CSV.write(it, "c:/timeseriesdatabase_output/high_aggregated_interpolated.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, false);		
		CSV.write(it, "c:/timeseriesdatabase_output/high_aggregated.csv", " ", "0", CSVTimeType.TIMESTAMP_AND_DATETIME);	
		
		System.out.println("...end");
	}

}
