package timeseriesdatabase;

import java.util.List;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.Interpolator;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import timeseriesdatabase.aggregated.iterator.BaseAggregationIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import timeseriesdatabase.raw.iterator.QualityFlagIterator;
import timeseriesdatabase.raw.iterator.BadQualityToNanIterator;
import util.Util;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;

public class QueryProcessor {
	
	final int STATION_INTERPOLATION_COUNT = 15;		
	final int TRAINING_TIME_INTERVAL = 60*24*7*4; // in minutes;  four weeks

	private static final Logger log = Util.log;

	private final TimeSeriesDatabase timeSeriesDatabase;

	public QueryProcessor(TimeSeriesDatabase timeSeriesDatabase) {
		this.timeSeriesDatabase = timeSeriesDatabase;
	}
	
	public TimeSeriesIterator query_raw(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		Station station = timeSeriesDatabase.stationMap.get(plotID);
		return Util.ifnull(station,x->x.queryRaw(querySchema, queryStart, queryEnd),()->{log.warn("plotID not found: "+plotID);return null;});
	}	
	
	public TimeSeriesIterator query_raw_with_quality_flags(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		TimeSeriesIterator input_iterator = query_raw(plotID, querySchema, queryStart, queryEnd);
		return Util.ifnull(input_iterator, x->new QualityFlagIterator(timeSeriesDatabase,x));		
	}
	
	public TimeSeriesIterator query_raw_with_bad_quality_removed(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TimeSeriesIterator qualityFlagIterator = query_raw_with_quality_flags(plotID, querySchema, queryStart, queryEnd);
		return Util.ifnull(dataQuality, x->new BadQualityToNanIterator(qualityFlagIterator,x));		
	}
	
	public TimeSeriesIterator query_base_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TimeSeriesIterator qualityRemoveIterator = query_raw_with_bad_quality_removed(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return Util.ifnull(qualityRemoveIterator, x->new BaseAggregationIterator(timeSeriesDatabase,x));
	}
	
	public TimeSeriesIterator query_aggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		TimeSeriesIterator baseAggregatedQualityIterator = query_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return Util.ifnull(baseAggregatedQualityIterator, x -> new AggregationIterator(timeSeriesDatabase, x, aggregationInterval));
	}
	
	public TimeSeriesIterator query_base_aggregated_interpolated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {


		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return null; 				
		}

		Long targetStart = queryStart==null ? null : queryStart-TRAINING_TIME_INTERVAL;
		Long targetEnd = queryEnd;	

		TimeSeriesIterator target_iterator = query_base_aggregated(plotID, querySchema, targetStart, targetEnd, dataQuality);
			
		
		target_iterator = new NanGapIterator(target_iterator, queryStart, queryEnd);
		TimeSeries targetTimeSeries = TimeSeries.create(target_iterator);
		if(targetTimeSeries==null) {
			return null;
		}

		long interpolationStartTimestamp = targetTimeSeries.getFirstTimestamp();
		long interpolationEndTimestamp = targetTimeSeries.getLastTimestamp();

		TimeSeries[] sourceTimeseries = new TimeSeries[STATION_INTERPOLATION_COUNT];
		List<Station> nearestStationList = station.nearestStationList;
		for(int i=0;i<STATION_INTERPOLATION_COUNT;i++) {
			Station sourceStation = nearestStationList.get(i);			
		
			TimeSeriesIterator source_iterator = query_base_aggregated(sourceStation.plotID, querySchema, interpolationStartTimestamp , interpolationEndTimestamp, dataQuality);
			
			source_iterator = new NanGapIterator(source_iterator, interpolationStartTimestamp, interpolationEndTimestamp);			
			sourceTimeseries[i] = TimeSeries.create(source_iterator);
		}
		
		String[] interpolationSensorNames = querySchema;
		if(querySchema==null) {
			interpolationSensorNames = station.getLoggerType().sensorNames;
		}
		
		for(String sensor:interpolationSensorNames) {
			if(timeSeriesDatabase.sensorMap.get(sensor).useInterpolation) {
				Interpolator.process(sourceTimeseries, targetTimeSeries, sensor);
			}
		}

		targetTimeSeries.hasDataInterpolatedFlag = true;
		
		return targetTimeSeries.timeSeriesIteratorCLIP(queryStart, queryEnd);		
	}
	
	
	public TimeSeriesIterator query_aggregated_interpolated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		TimeSeriesIterator input_iterator = query_base_aggregated_interpolated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		if(input_iterator==null) {
			return null;
		}
		return new AggregationIterator(timeSeriesDatabase, input_iterator, aggregationInterval);		
	}
	
	public TimeSeriesIterator TestingAggregatadQualityQuery(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) {
		if(interpolated) {
			return query_aggregated_interpolated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		} else {
			return query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		}
	}
}
