package tsdb;

import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;

import tsdb.aggregated.AggregationInterval;
import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.aggregated.Interpolator;
import tsdb.aggregated.TimeSeries;
import tsdb.aggregated.iterator.AggregationIterator;
import tsdb.aggregated.iterator.BadInterpolatedRemoveIterator;
import tsdb.aggregated.iterator.BaseAggregationIterator;
import tsdb.aggregated.iterator.EmpiricalIterator;
import tsdb.aggregated.iterator.NanGapIterator;
import tsdb.aggregated.iterator.VirtualPlotIterator;
import tsdb.raw.iterator.LowQualityToNanIterator;
import tsdb.raw.iterator.QualityFlagIterator;
import tsdb.util.Builder;
import tsdb.util.TimestampInterval;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

/**
 * QueryProcessor processes raw elements from storage and provides methods for typical queries. Date is returned
 * as TimeSeriesIterator object.
 * @author woellauer
 *
 */
@Deprecated
public class QueryProcessor extends TsDBClient {

	final int STATION_INTERPOLATION_COUNT = 15;		
	final int TRAINING_TIME_INTERVAL = 60*24*7*4; // in minutes;  four weeks


	public QueryProcessor(TsDB tsdb) {
		super(tsdb);
	}

	/**
	 * Query one unprocessed time series
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @return
	 */
	public TsIterator query_raw(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		Station station = tsdb.getStation(plotID);
		return Util.ifnull(station,x->x.queryRaw(querySchema, queryStart, queryEnd),()->{log.warn("plotID not found: "+plotID);return null;});
	}	

	/**
	 * Query one unprocessed time series with added quality flags
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @return
	 */
	public TsIterator query_raw_with_quality_flags(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		TsIterator input_iterator = query_raw(plotID, querySchema, queryStart, queryEnd);
		return Util.ifnull(input_iterator, x->new QualityFlagIterator(tsdb,x));		
	}

	/**
	 * Query one not aggregated time series with data values with low quality removed
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @param dataQuality
	 * @return
	 */
	public TsIterator query_raw_with_bad_quality_removed(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TsIterator qualityFlagIterator = query_raw_with_quality_flags(plotID, querySchema, queryStart, queryEnd);
		return Util.ifnull(qualityFlagIterator, x->new LowQualityToNanIterator(x,dataQuality));		
	}

	/**
	 * Query one base aggregated time series
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @param dataQuality
	 * @return
	 */
	public TsIterator query_base_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TsIterator qualityRemoveIterator = query_raw_with_bad_quality_removed(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return Util.ifnull(qualityRemoveIterator, x->new BaseAggregationIterator(tsdb,x));
	}

	/**
	 * Query one base aggregated time series with added nan-elements in data gaps in time
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @param dataQuality
	 * @return
	 */
	public TsIterator query_continuous_base_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TsIterator input_iterator = query_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		Long start = Util.ifnull(queryStart, x->BaseAggregationTimeUtil.calcBaseAggregationTimestamp(x));
		Long end = Util.ifnull(queryEnd, x->BaseAggregationTimeUtil.calcBaseAggregationTimestamp(x));		
		return Util.ifnull(input_iterator, x->new NanGapIterator(input_iterator, start, end));
	}

	/**
	 * Query one base aggregated time series with added interpolated or nan-elements for data gaps in time
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @param dataQuality
	 * @return
	 */
	public TsIterator query_base_aggregated_interpolated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		Station station = tsdb.getStation(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return null; 				
		}

		Long targetStart =  Util.ifnull(queryStart, x->x-TRAINING_TIME_INTERVAL);
		Long targetEnd = queryEnd;	

		TsIterator target_iterator =  query_continuous_base_aggregated(plotID, querySchema, targetStart, targetEnd, dataQuality);			
		//target_iterator = new NanGapIterator(target_iterator, queryStart, queryEnd);
		if(target_iterator==null) {
			return null;
		}

		TimeSeries targetTimeSeries = TimeSeries.create(target_iterator);
		if(targetTimeSeries==null) {
			return null;
		}

		long interpolationStartTimestamp = targetTimeSeries.getFirstTimestamp();
		long interpolationEndTimestamp = targetTimeSeries.getLastTimestamp();

		String[] tempSchema = querySchema;
		if(querySchema==null) {
			tempSchema = station.loggerType.sensorNames;
		}		
		ArrayList<String> tempInterpolationSensorNameList = new ArrayList<String>();
		for(String sensorName:tempSchema) {
			if(tsdb.getSensor(sensorName).useInterpolation) {
				tempInterpolationSensorNameList.add(sensorName);
			}
		}		
		String[] interpolationSensorNames = tempInterpolationSensorNameList.toArray(new String[0]);


		TimeSeries[] sourceTimeseries = new TimeSeries[STATION_INTERPOLATION_COUNT];
		List<Station> nearestStationList = station.nearestStations;
		for(int i=0;i<STATION_INTERPOLATION_COUNT;i++) {
			Station sourceStation = nearestStationList.get(i);			
			String[] qNames = sourceStation.getValidSchemaEntries(interpolationSensorNames);
			if(qNames.length>0) {
				TsIterator source_iterator = query_continuous_base_aggregated(sourceStation.stationID, qNames, interpolationStartTimestamp , interpolationEndTimestamp, dataQuality);			
				sourceTimeseries[i] = TimeSeries.create(source_iterator);
			} else {
				sourceTimeseries[i] = null;
			}
		}

		int interpolatedCount = 0;
		for(String sensor:interpolationSensorNames) {
			interpolatedCount += Interpolator.process(sourceTimeseries, targetTimeSeries, sensor);
		}

		if(interpolatedCount>0) { // Quality check interpolated values
			System.out.println("interpolation count: "+interpolatedCount);
		}

		targetTimeSeries.hasDataInterpolatedFlag = true;		
		TsIterator clipIterator = targetTimeSeries.timeSeriesIteratorCLIP(queryStart, queryEnd);
		return new BadInterpolatedRemoveIterator(tsdb, clipIterator);
	}

	/**
	 * Query one high aggregated time series without interpolation
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @param dataQuality
	 * @param aggregationInterval
	 * @return
	 */
	public TsIterator query_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		TsIterator baseAggregatedQualityIterator = query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return Util.ifnull(baseAggregatedQualityIterator, x -> new AggregationIterator(tsdb, x, aggregationInterval));
	}


	/**
	 * Query one high aggregated time series with interpolation
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @param dataQuality
	 * @param aggregationInterval
	 * @return
	 */
	public TsIterator query_aggregated_interpolated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		TsIterator input_iterator = query_base_aggregated_interpolated(plotID, querySchema, queryStart, queryEnd, dataQuality);		
		return Util.ifnull(input_iterator,x->new AggregationIterator(tsdb, x, aggregationInterval));
	}

	/**
	 * Query one high aggregated time series with or without interpolation
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @param dataQuality
	 * @param aggregationInterval
	 * @param interpolated
	 * @return
	 */
	public TsIterator query_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) {
		if(interpolated) {
			return query_aggregated_interpolated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		} else {
			return query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		}
	}

	/**
	 * Same as query_continuous_base_aggregated with empirical diff check.
	 * @param plotID
	 * @param querySchema may be null
	 * @param queryStart may be null
	 * @param queryEnd may be null
	 * @param dataQuality used for processing before empirical diff check.
	 * @return
	 */
	public TsIterator query_empirical_diff_check(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		if(queryStart==null||queryEnd==null) {
			long[] interval = tsdb.getTimeInterval(plotID);
			if(queryStart==null) {
				queryStart = interval[0];
			}
			if(queryEnd==null) {
				queryEnd = interval[1];
			}
		}
		String generalName = tsdb.getStation(plotID).generalStation.name;
		TsIterator input_iterator = query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		TsIterator compare_iterator = Builder.project(Builder.continuous(tsdb.cacheStorage.query(generalName, queryStart, queryEnd), queryStart, queryEnd),input_iterator);
		Float[] maxDiff = tsdb.getEmpiricalDiff(input_iterator.getNames());
		float[] refValues = tsdb.getReferenceValues(plotID,input_iterator.getNames());
		System.out.println("maxDiff[0]: "+maxDiff[0]);
		return new EmpiricalIterator(input_iterator, compare_iterator, maxDiff, refValues);
	}

	public TsIterator virtualquery_base_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, boolean interpolated) {
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			if(querySchema==null) {
				querySchema = tsdb.getBaseSchema(virtualPlot.getSchema());
			}
			List<TimestampInterval<StationProperties>> intervalList = virtualPlot.getStationList(queryStart, queryEnd, querySchema);			 
			List<TsIterator> processing_iteratorList = new ArrayList<TsIterator>();				
			for(TimestampInterval<StationProperties> interval:intervalList) {
				String[] stationSchema = tsdb.getValidSchema(interval.value.get_serial(),querySchema);
				if(stationSchema.length==0) {
					log.warn("schema empty");
				}
				TsIterator it = this.query_base_aggregated(interval.value.get_serial(), stationSchema, interval.start, interval.end, dataQuality);
				if(it!=null&&it.hasNext()) {
					System.out.println("add iterator: ["+interval.value.get_serial()+"] plotID "+interval.value.get_plotid());
					processing_iteratorList.add(it);
				}
			}
			if(processing_iteratorList.isEmpty()) {
				return null;
			}
			VirtualPlotIterator it_virtual_base_aggregated = new VirtualPlotIterator(querySchema, processing_iteratorList.toArray(new TsIterator[0]),plotID);			
			Long start = Util.ifnull(queryStart, x->BaseAggregationTimeUtil.calcBaseAggregationTimestamp(x));
			Long end = Util.ifnull(queryEnd, x->BaseAggregationTimeUtil.calcBaseAggregationTimestamp(x));		
			TsIterator it_continuous_base_aggregated = Util.ifnull(it_virtual_base_aggregated, x->new NanGapIterator(x, start, end));
			return it_continuous_base_aggregated;
			//return it_virtual_base_aggregated;

		} else if(tsdb.stationExists(plotID)){
			return query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, AggregationInterval.HOUR, interpolated);
		} else {
			return null;
		}
	}

	public TsIterator virtualquery_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) {
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			TsIterator it_continuous_base_aggregated = virtualquery_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, interpolated);
			return Util.ifnull(it_continuous_base_aggregated, x -> new AggregationIterator(tsdb, x, aggregationInterval));
		} else if(tsdb.stationExists(plotID)){
			return query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
		} else {
			return null;
		}
	}


}
