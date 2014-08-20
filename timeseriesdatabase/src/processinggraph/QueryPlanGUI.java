package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import util.iterator.TimeSeriesIterator;

public class QueryPlanGUI {
	/*
	 *				 Node node;
					if(useCache) {
						String streamName = plotID;
						node = Aggregated.createFromBase(timeSeriesDatabase, CacheBase.create(timeSeriesDatabase, streamName, querySchema), agg);
					} else if(useInterpolation) {
						node = Aggregated.createInterpolated(timeSeriesDatabase, plotID, querySchema, agg, dataQuality);
					} else {
						node = Aggregated.create(timeSeriesDatabase, plotID, querySchema, agg, dataQuality);
					}
					TimeSeriesIterator it = node.get(queryStart, queryEnd);
					if(it!=null&&it.hasNext()) {
						resultTimeSeries = it.toTimestampSeries();
	 * 
	 * 
	 */

	public static Node cache(TimeSeriesDatabase timeSeriesDatabase, String streamName, String columnName, AggregationInterval aggregationInterval) {		
		CacheBase base = CacheBase.create(timeSeriesDatabase, streamName, new String[]{columnName});
		return Aggregated.createFromBase(timeSeriesDatabase, base, aggregationInterval);		
	}
	
	public static Node plot(TimeSeriesDatabase timeSeriesDatabase, String plotID, String columnName, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated) {
		String[] querySchema = new String[]{columnName};
		Continuous source = Continuous.create(timeSeriesDatabase, plotID, querySchema , dataQuality);	
		
		NodeFunc func = QueryPlanGUI::testingFunc;
		
		
		return Aggregated.create(timeSeriesDatabase, plotID, new String[]{columnName}, aggregationInterval, dataQuality);
	}
	
	public static Continuous testingFunc(String plotID, String[] schema) {
		return null;
	}

}
