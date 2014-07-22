package timeseriesdatabase;

import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;





import util.Builder;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.aggregated.Interpolator;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import timeseriesdatabase.aggregated.iterator.BadInterpolatedRemoveIterator;
import timeseriesdatabase.aggregated.iterator.BaseAggregationIterator;
import timeseriesdatabase.aggregated.iterator.EmpiricalIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import timeseriesdatabase.raw.iterator.QualityFlagIterator;
import timeseriesdatabase.raw.iterator.BadQualityToNanIterator;
import util.Util;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;

/**
 * QueryProcessor processes raw elements from storage and provides methods for typical queries. Date is returned
 * as TimeSeriesIterator object.
 * @author woellauer
 *
 */
public class QueryProcessor {

	final int STATION_INTERPOLATION_COUNT = 15;		
	final int TRAINING_TIME_INTERVAL = 60*24*7*4; // in minutes;  four weeks

	private static final Logger log = Util.log;

	private final TimeSeriesDatabase timeSeriesDatabase;

	public QueryProcessor(TimeSeriesDatabase timeSeriesDatabase) {
		this.timeSeriesDatabase = timeSeriesDatabase;
	}

	/**
	 * Query one unprocessed time series
	 * @param plotID
	 * @param querySchema
	 * @param queryStart
	 * @param queryEnd
	 * @return
	 */
	public TimeSeriesIterator query_raw(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		Station station = timeSeriesDatabase.stationMap.get(plotID);
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
	public TimeSeriesIterator query_raw_with_quality_flags(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		TimeSeriesIterator input_iterator = query_raw(plotID, querySchema, queryStart, queryEnd);
		return Util.ifnull(input_iterator, x->new QualityFlagIterator(timeSeriesDatabase,x));		
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
	public TimeSeriesIterator query_raw_with_bad_quality_removed(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TimeSeriesIterator qualityFlagIterator = query_raw_with_quality_flags(plotID, querySchema, queryStart, queryEnd);
		return Util.ifnull(qualityFlagIterator, x->new BadQualityToNanIterator(x,dataQuality));		
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
	public TimeSeriesIterator query_base_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TimeSeriesIterator qualityRemoveIterator = query_raw_with_bad_quality_removed(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return Util.ifnull(qualityRemoveIterator, x->new BaseAggregationIterator(timeSeriesDatabase,x));
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
	public TimeSeriesIterator query_continuous_base_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TimeSeriesIterator input_iterator = query_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
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
	public TimeSeriesIterator query_base_aggregated_interpolated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		Station station = timeSeriesDatabase.getStation(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return null; 				
		}

		Long targetStart =  Util.ifnull(queryStart, x->x-TRAINING_TIME_INTERVAL);
		Long targetEnd = queryEnd;	

		TimeSeriesIterator target_iterator =  query_continuous_base_aggregated(plotID, querySchema, targetStart, targetEnd, dataQuality);			
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
			tempSchema = station.getLoggerType().sensorNames;
		}		
		ArrayList<String> tempInterpolationSensorNameList = new ArrayList<String>();
		for(String sensorName:tempSchema) {
			if(timeSeriesDatabase.sensorMap.get(sensorName).useInterpolation) {
				tempInterpolationSensorNameList.add(sensorName);
			}
		}		
		String[] interpolationSensorNames = tempInterpolationSensorNameList.toArray(new String[0]);


		TimeSeries[] sourceTimeseries = new TimeSeries[STATION_INTERPOLATION_COUNT];
		List<Station> nearestStationList = station.nearestStationList;
		for(int i=0;i<STATION_INTERPOLATION_COUNT;i++) {
			Station sourceStation = nearestStationList.get(i);			
			String[] qNames = sourceStation.getValidSchemaEntries(interpolationSensorNames);
			if(qNames!=null) {
			TimeSeriesIterator source_iterator = query_continuous_base_aggregated(sourceStation.plotID, qNames, interpolationStartTimestamp , interpolationEndTimestamp, dataQuality);			
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
		TimeSeriesIterator clipIterator = targetTimeSeries.timeSeriesIteratorCLIP(queryStart, queryEnd);
		return new BadInterpolatedRemoveIterator(timeSeriesDatabase, clipIterator);
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
	public TimeSeriesIterator query_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		TimeSeriesIterator baseAggregatedQualityIterator = query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return Util.ifnull(baseAggregatedQualityIterator, x -> new AggregationIterator(timeSeriesDatabase, x, aggregationInterval));
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
	public TimeSeriesIterator query_aggregated_interpolated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		TimeSeriesIterator input_iterator = query_base_aggregated_interpolated(plotID, querySchema, queryStart, queryEnd, dataQuality);		
		return Util.ifnull(input_iterator,x->new AggregationIterator(timeSeriesDatabase, x, aggregationInterval));
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
	public TimeSeriesIterator query_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) {
		if(interpolated) {
			return query_aggregated_interpolated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		} else {
			return query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		}
	}
	
	public TimeSeriesIterator query_empirical_diff_check(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		if(queryStart==null) {
			queryStart = timeSeriesDatabase.getFirstTimestamp(plotID);
		}
		if(queryEnd==null) {
			queryEnd = timeSeriesDatabase.getLastTimestamp(plotID);
		}
		String generalName = timeSeriesDatabase.getStation(plotID).generalStationName;
		TimeSeriesIterator input_iterator = query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		TimeSeriesIterator compare_iterator = Builder.project(Builder.fill(timeSeriesDatabase.cacheStorage.query(generalName, queryStart, queryEnd), queryStart, queryEnd),input_iterator);
		Float[] maxDiff = timeSeriesDatabase.getEmpiricalDiff(input_iterator.getOutputSchema());
		System.out.println("maxDiff[0]: "+maxDiff[0]);
		return new EmpiricalIterator(input_iterator, compare_iterator, maxDiff);
	}
	
	
}
