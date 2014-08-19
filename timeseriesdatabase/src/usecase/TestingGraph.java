package usecase;

import processinggraph.Aggregated;
import processinggraph.Base;
import processinggraph.Interpolated;
import processinggraph.StationBase;
import processinggraph.Continuous;
import processinggraph.Node;
import processinggraph.RawSource;
import timeseriesdatabase.DataQuality;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.iterator.TimeSeriesIterator;

public class TestingGraph {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		//String stationName = "HEG01";
		//String stationName = "8";
		//String stationName = "fer0";
		String stationName = "cof3";
		String[] querySchema = null;
		AggregationInterval aggregationInterval = AggregationInterval.MONTH;
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		//Node node = Base.create(timeSeriesDatabase, stationName, querySchema, dataQuality);
		//Node node = Continuous.create(timeSeriesDatabase, stationName, querySchema);
		//Node node = Aggregated.create(timeSeriesDatabase, stationName, querySchema, aggregationInterval);
		//Node node = Interpolated.create(timeSeriesDatabase, stationName, querySchema, DataQuality.EMPIRICAL);
		Node node = Aggregated.createInterpolated(timeSeriesDatabase, stationName, querySchema, aggregationInterval, dataQuality);
		Long start = null;
		Long end = null;
		//TimeSeriesIterator it = node.get(start, end);
		
		//node.writeCSV(start, end, CSV_OUTPUT_PATH+"TestingGraph.csv");
		node.writeConsole(start, end);

		//it = new AggregationIterator(timeSeriesDatabase, it, aggregationInterval);
		
	
		//it.writeCSV(CSV_OUTPUT_PATH+"TestingGraph.csv");
		//it.writeConsole();
		
		System.out.println("...end");
	}

}
