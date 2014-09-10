package tsdb.graph;

import tsdb.DataQuality;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;

/**
 * With QueryPlan query graphs for specific queries a are build
 * @author woellauer
 *
 */
public class QueryPlan {

	/**
	 * Creates a general purpose graph for queries over one plot
	 * @param tsdb
	 * @param plotID
	 * @param columnName
	 * @param aggregationInterval
	 * @param dataQuality
	 * @param interpolated
	 * @return
	 */
	public static Node plot(TsDB tsdb, String plotID, String[] columnNames, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated) {
		String[] schema = columnNames;
		ContinuousGen continuousGen = getContinuousGen(tsdb, dataQuality);
		Continuous continuous;
		if(interpolated) {
			continuous = Interpolated.create(tsdb, plotID, schema, continuousGen); 
		} else {
			continuous = continuousGen.get(plotID, schema);
		}
		//!!!TODO
		//continuous = Difference.createFromGroupAverage(tsdb, continuous, plotID, false);
		//!!!TODO
		if(AggregationInterval.HOUR==aggregationInterval) {
			return continuous;
		} else {
			return Aggregated.create(tsdb, continuous, aggregationInterval);
		}		
	}

	/**
	 * creaets a generator of a continuous source
	 * @param tsdb
	 * @param dataQuality
	 * @return
	 */
	public static ContinuousGen getContinuousGen(TsDB tsdb, DataQuality dataQuality) {
		return (String plotID, String[] schema)->{
			NodeGen stationGen = getStationGen(tsdb, dataQuality);		
			Base base = Base.create(tsdb, plotID, schema, stationGen);
			Continuous continuous = Continuous.create(base);
			if(DataQuality.EMPIRICAL==dataQuality) {
				continuous = EmpiricalFiltered.create(tsdb, continuous, plotID);
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
				rawSource = PeakSmoothed.create(rawSource);
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
	 * @param tsdb
	 * @param streamName
	 * @param columnName
	 * @param aggregationInterval
	 * @return
	 */
	public static Node cache(TsDB tsdb, String streamName, String[] columnNames, AggregationInterval aggregationInterval) {		
		CacheBase base = CacheBase.create(tsdb, streamName, columnNames);
		Continuous continuous = Continuous.create(base);
		return Aggregated.create(tsdb, continuous, aggregationInterval);		
	}	

}
