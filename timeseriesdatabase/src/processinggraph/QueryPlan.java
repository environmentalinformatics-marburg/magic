package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import util.iterator.TimeSeriesIterator;

public class QueryPlan {

	public static Node plot(TimeSeriesDatabase timeSeriesDatabase, String plotID, String columnName, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated) {
		String[] schema = new String[]{columnName};
		ContinuousGen continuousGen = getContinuousGen(timeSeriesDatabase, dataQuality);
		Continuous_temp continuous;
		if(interpolated) {
			continuous = Interpolated.create(timeSeriesDatabase, plotID, schema, continuousGen); 
		} else {
			continuous = continuousGen.get(plotID, schema);
		}
		if(AggregationInterval.HOUR==aggregationInterval) {
			return continuous;
		} else {
			return Aggregated.create(timeSeriesDatabase, continuous, aggregationInterval);
		}		
	}

	public static ContinuousGen getContinuousGen(TimeSeriesDatabase timeSeriesDatabase, DataQuality dataQuality) {
		return (String plotID, String[] schema)->{
			NodeGen stationGen = getStationGen(timeSeriesDatabase, dataQuality);		
			Base base = Base.create(timeSeriesDatabase, plotID, schema, stationGen);
			return Continuous_temp.create(timeSeriesDatabase, base);
		};
	}

	public static NodeGen getStationGen(TimeSeriesDatabase timeSeriesDatabase, DataQuality dataQuality) {
		return (String stationID, String[] schema)->{
			Station station = timeSeriesDatabase.getStation(stationID);
			if(station==null) {
				throw new RuntimeException("station not found");
			}
			Node rawSource = RawSource.create(timeSeriesDatabase, stationID, schema);
			if(station.loggerType.typeName.equals("tfi")) {
				rawSource = PeakSmoothed.create(timeSeriesDatabase,rawSource);
			}			
			if(DataQuality.Na==dataQuality) {
				return rawSource;
			} else {
				return QualityFilter.create(timeSeriesDatabase, rawSource, dataQuality);
			}
		};
	}

	public static Node cache(TimeSeriesDatabase timeSeriesDatabase, String streamName, String columnName, AggregationInterval aggregationInterval) {		
		CacheBase base = CacheBase.create(timeSeriesDatabase, streamName, new String[]{columnName});
		Continuous_temp continuous = Continuous_temp.create(timeSeriesDatabase, base);
		return Aggregated.create(timeSeriesDatabase, continuous, aggregationInterval);		
	}	

}
