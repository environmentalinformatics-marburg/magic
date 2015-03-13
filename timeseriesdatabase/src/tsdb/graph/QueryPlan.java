package tsdb.graph;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.TsDB;
import tsdb.util.AggregationInterval;
import tsdb.util.DataQuality;
import tsdb.util.Util;

/**
 * With QueryPlan query graphs for specific queries a are build
 * @author woellauer
 *
 */
public class QueryPlan {
	private static final Logger log = LogManager.getLogger();

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

		if(plotID.indexOf(':')<0) { //plotID without sub station
			if(aggregationInterval!=AggregationInterval.RAW) { // aggregated
				ContinuousGen continuousGen = getContinuousGen(tsdb, dataQuality);
				Continuous continuous;
				if(interpolated) {
					continuous = Interpolated.of(tsdb, plotID, schema, continuousGen); 
				} else {
					continuous = continuousGen.get(plotID, schema);
				}
				return Aggregated.of(tsdb, continuous, aggregationInterval);
			} else { // raw
				if(dataQuality!=DataQuality.NO&&dataQuality!=DataQuality.Na) {
					dataQuality = DataQuality.NO;
					log.warn("raw query quality check not supported");
				}
				if(interpolated) {
					interpolated = false;
					log.warn("raw query interpolation not supported");
				}
				return RawSource.of(tsdb, plotID, schema);
			}			
		} else { // plotID of structure plotID:stationID
			if(aggregationInterval!=AggregationInterval.RAW) { // aggregated
				if(dataQuality==DataQuality.EMPIRICAL) {
					dataQuality = DataQuality.STEP;
					log.warn("query of plotID:stationID: DataQuality.EMPIRICAL not supported");
				}
				if(interpolated) {
					interpolated = false;
					log.warn("query of plotID:stationID: interpolation not supported");
				}
				String[] parts = plotID.split(":");
				if(parts.length!=2) {
					log.error("not valid name: "+plotID);
					return null;
				}
				NodeGen stationGen = getStationGen(tsdb, dataQuality);
				Base base = VirtualPlotStationBase.of(tsdb, parts[0], parts[1], schema, stationGen);
				if(base==null) {
					return null;
				}
				Continuous continuous = Continuous.of(base);
				return Aggregated.of(tsdb, continuous, aggregationInterval);
			} else { // raw
				if(dataQuality!=DataQuality.NO&&dataQuality!=DataQuality.Na) {
					dataQuality = DataQuality.NO;
					log.warn("raw query quality check not supported");
				}
				if(interpolated) {
					interpolated = false;
					log.warn("raw query interpolation not supported");
				}
				String[] parts = plotID.split(":");
				if(parts.length!=2) {
					log.error("not valid name: "+plotID);
					return null;
				}
				return VirtualPlotStationRawSource.of(tsdb, parts[0], parts[1], schema);
			}	
		}

	}

	public static Node plotDifference(TsDB tsdb, String plotID, String[] columnNames, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated) {
		String[] schema = columnNames;
		ContinuousGen continuousGen = getContinuousGen(tsdb, dataQuality);
		Continuous continuous;
		if(interpolated) {
			continuous = Interpolated.of(tsdb, plotID, schema, continuousGen); 
		} else {
			continuous = continuousGen.get(plotID, schema);
		}
		continuous = Difference.createFromGroupAverage(tsdb, continuous, plotID, false);
		return Aggregated.of(tsdb, continuous, aggregationInterval);		
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
			Base base = Base.of(tsdb, plotID, schema, stationGen);
			if(base==null) {
				return null;
			}
			Continuous continuous = Continuous.of(base);
			if(DataQuality.EMPIRICAL==dataQuality) {
				continuous = EmpiricalFiltered.of(tsdb, continuous, plotID);
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
			boolean virtual_P_RT_NRT = false;
			if(station.generalStation!=null && station.generalStation.region.name.equals("BE") && Util.containsString(schema, "P_RT_NRT")) {
				virtual_P_RT_NRT = true;				
				if(!Util.containsString(schema, "P_container_RT")) {
					schema = Util.concat(schema,"P_container_RT");
				}
			}
			Node rawSource = StationRawSource.of(tsdb, stationID, schema);
			if(virtual_P_RT_NRT) {
				//log.info("add virtual_P_RT_NRT in "+stationID);
				rawSource = Virtual_P_RT_NRT.of(tsdb, rawSource);
			}
			if(station.loggerType.typeName.equals("tfi")) {
				rawSource = PeakSmoothed.of(rawSource);
			}			
			if(DataQuality.Na==dataQuality) {
				return rawSource;
			} else {
				return RangeStepFiltered.of(tsdb, rawSource, dataQuality);
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
		CacheBase base = CacheBase.of(tsdb, streamName, columnNames);
		Continuous continuous = Continuous.of(base);
		return Aggregated.of(tsdb, continuous, aggregationInterval);		
	}	

}
