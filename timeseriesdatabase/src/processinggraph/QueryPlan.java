package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import util.iterator.TimeSeriesIterator;

/**
 * With QueryPlan query graphs for specific queries a are build
 * @author woellauer
 *
 */
public class QueryPlan {

	/**
	 * Creates a general purpose graph for queries over one plot
	 * @param timeSeriesDatabase
	 * @param plotID
	 * @param columnName
	 * @param aggregationInterval
	 * @param dataQuality
	 * @param interpolated
	 * @return
	 */
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

	/**
	 * creaets a generator of a continuous source
	 * @param timeSeriesDatabase
	 * @param dataQuality
	 * @return
	 */
	public static ContinuousGen getContinuousGen(TimeSeriesDatabase timeSeriesDatabase, DataQuality dataQuality) {
		return (String plotID, String[] schema)->{
			NodeGen stationGen = getStationGen(timeSeriesDatabase, dataQuality);		
			Base base = Base.create(timeSeriesDatabase, plotID, schema, stationGen);
			return Continuous_temp.create(timeSeriesDatabase, base);
		};
	}

	/**
	 * creates a generator of a station raw data with quality check
	 * @param timeSeriesDatabase
	 * @param dataQuality
	 * @return
	 */
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

	/**
	 * Creates a graph for a cache source
	 * @param timeSeriesDatabase
	 * @param streamName
	 * @param columnName
	 * @param aggregationInterval
	 * @return
	 */
	public static Node cache(TimeSeriesDatabase timeSeriesDatabase, String streamName, String columnName, AggregationInterval aggregationInterval) {		
		CacheBase base = CacheBase.create(timeSeriesDatabase, streamName, new String[]{columnName});
		Continuous_temp continuous = Continuous_temp.create(timeSeriesDatabase, base);
		return Aggregated.create(timeSeriesDatabase, continuous, aggregationInterval);		
	}	

}
