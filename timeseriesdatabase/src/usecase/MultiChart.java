package usecase;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationType;
import util.CSV;
import util.iterator.TimeSeriesIterator;

public class MultiChart {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		GeneralStation generalStation = timeSeriesDatabase.generalStationMap.get("HEW");
		
		String[] querySchema = new String[]{"Ta_200"};
		Long queryStart = null;
		Long queryEnd = null;
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		AggregationInterval aggregationInterval = AggregationInterval.DAY;
		
		for(Station station:generalStation.stationList) {			
			TimeSeriesIterator it = qp.query_aggregated(station.plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
			CSV.write(it,CSV_OUTPUT_PATH+"multichar_"+station.plotID+".csv");
		}
		
		
		System.out.println("...end");

	}

}
