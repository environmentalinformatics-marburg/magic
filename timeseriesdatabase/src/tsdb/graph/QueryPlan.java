package tsdb.graph;

import tsdb.DataQuality;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.util.iterator.TimeSeriesIterator;

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
	public static Node plot(TsDB timeSeriesDatabase, String plotID, String columnName, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated) {
		String[] schema = new String[]{columnName};
		ContinuousGen continuousGen = getContinuousGen(timeSeriesDatabase, dataQuality);
		Continuous continuous;
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
	public static ContinuousGen getContinuousGen(TsDB timeSeriesDatabase, DataQuality dataQuality) {
		return (String plotID, String[] schema)->{
			NodeGen stationGen = getStationGen(timeSeriesDatabase, dataQuality);		
			Base base = Base.create(timeSeriesDatabase, plotID, schema, stationGen);
			Continuous continuous = Continuous.create(timeSeriesDatabase, base);
			if(DataQuality.EMPIRICAL==dataQuality) {
				continuous = EmpiricalFiltered.create(timeSeriesDatabase, continuous, plotID);
			}
			return continuous;
		};
	}

	/**
	 * creates a generator of a station raw data with quality check
	 * @param tsdb
	 * @param dataQuality
	 * @return
	 */
	public static NodeGen getStationGen(TsDB tsdb, DataQuality dataQuality) {
		return (String stationID, String[] schema)->{
			Station station = tsdb.getStation(stationID);
			if(station==null) {
				throw new RuntimeException("station not found");
			}
			Node rawSource = RawSource.create(tsdb, stationID, schema);
			if(station.loggerType.typeName.equals("tfi")) {
				rawSource = PeakSmoothed.create(tsdb,rawSource);
			}			
			if(DataQuality.Na==dataQuality) {
				return rawSource;
			} else {
				return RangeStepFiltered.create(tsdb, rawSource, dataQuality);
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
	public static Node cache(TsDB timeSeriesDatabase, String streamName, String columnName, AggregationInterval aggregationInterval) {		
		CacheBase base = CacheBase.create(timeSeriesDatabase, streamName, new String[]{columnName});
		Continuous continuous = Continuous.create(timeSeriesDatabase, base);
		return Aggregated.create(timeSeriesDatabase, continuous, aggregationInterval);		
	}	

}
