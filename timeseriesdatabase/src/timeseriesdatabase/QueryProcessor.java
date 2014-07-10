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
import timeseriesdatabase.raw.iterator.QualityToNanIterator;
import util.Util;
import util.iterator.SchemaIterator;
import util.iterator.TimeSeriesIterator;

public class QueryProcessor {

	private static final Logger log = Util.log;

	private final TimeSeriesDatabase timeSeriesDatabase;

	public QueryProcessor(TimeSeriesDatabase timeSeriesDatabase) {
		this.timeSeriesDatabase = timeSeriesDatabase;
	}

	public TimeSeriesIterator queryRaw(String plotID, String[] querySchema, Long start, Long end) {
		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station!=null) {
			return station.queryRaw(querySchema, start, end);
		} else {
			return null;
		}
	}

	public TimeSeriesIterator queryRawQualityChecked(String plotID, String[] querySchema, Long start, Long end, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station!=null) {
			return station.queryRawQualityChecked(querySchema, start, end, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
		} else {
			return null;
		}
	}

	public TimeSeriesIterator queryBaseAggregated(String plotID, String[] querySchema, Long start, Long end, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station!=null) {
			return station.queryBaseAggregated(querySchema, start, end, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
		} else {
			return null;
		}		
	}

	public TimeSeries queryInterpolatedTimeSeries(String plotID, String[] querySchema, Long queryStart, Long queryEnd, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		final int STATION_INTERPOLATION_COUNT = 15;		
		final int TRAINING_TIME_INTERVAL = 60*24*7*4; // in minutes;  four weeks

		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return null; 				
		}

		Long targetStart = queryStart==null ? null : queryStart-TRAINING_TIME_INTERVAL;
		Long targetEnd = queryEnd;	

		TimeSeriesIterator target_iterator = station.queryBaseAggregated(querySchema, targetStart, targetEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
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
			TimeSeriesIterator source_iterator = sourceStation.queryBaseAggregated(querySchema, interpolationStartTimestamp, interpolationEndTimestamp, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
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

		return targetTimeSeries.getClipped(queryStart, queryEnd);	
	}	

	public TimeSeriesIterator queryAggregated(String plotID, String[] querySchema, Long queryStart, Long queryEnd, AggregationInterval aggregationInterval, boolean checkPhysicalRange, boolean checkEmpiricalRange, boolean  checkStepRange, boolean useInterpolation) {
		/*
		 * TODO
		 * if(querySchema == null) use only sensors that are defined for base aggregation
		 * 
		 * 
		 */
		
		if(useInterpolation) {
			TimeSeries timeSeries = queryInterpolatedTimeSeries(plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
			return new AggregationIterator(timeSeriesDatabase, timeSeries.timeSeriesIterator(), aggregationInterval);
		} else {
			TimeSeriesIterator it = queryBaseAggregated(plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
			it = new NanGapIterator(it, queryStart, queryStart);
			return new AggregationIterator(timeSeriesDatabase, it, aggregationInterval);
		}
	}
	
	public TimeSeriesIterator TestingQualityQuery(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		
		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return null; 				
		}
		
		TimeSeriesIterator input_iterator = station.queryRaw(querySchema, queryStart, queryEnd);
		QualityFlagIterator qualityFlagIterator = new QualityFlagIterator(timeSeriesDatabase, input_iterator);
		QualityToNanIterator qualityNanIterator = new QualityToNanIterator(qualityFlagIterator, dataQuality);
		
		return qualityNanIterator;
		
	}
	
	public TimeSeriesIterator TestingBaseAggregatadQualityQuery(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		TimeSeriesIterator qualityIterator = TestingQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return new BaseAggregationIterator(timeSeriesDatabase,qualityIterator);
	}
	
	public TimeSeriesIterator TestingAggregatadQualityQuery(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		TimeSeriesIterator baseAggregatedQualityIterator = TestingBaseAggregatadQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality);
		return new AggregationIterator(timeSeriesDatabase, baseAggregatedQualityIterator, aggregationInterval);
	}
	
	public TimeSeriesIterator TestingInterpolatedBaseAggregatadQualityQuery(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		//TimeSeriesIterator baseAggregatedQualityIterator = TestingBaseAggregatadQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality);
		//TODO
		//return baseAggregatedQualityIterator;
		
		
		final int STATION_INTERPOLATION_COUNT = 15;		
		final int TRAINING_TIME_INTERVAL = 60*24*7*4; // in minutes;  four weeks

		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station==null) {
			log.warn("plotID not found: "+plotID);
			return null; 				
		}

		Long targetStart = queryStart==null ? null : queryStart-TRAINING_TIME_INTERVAL;
		Long targetEnd = queryEnd;	

		//TimeSeriesIterator target_iterator = station.queryBaseAggregated(querySchema, targetStart, targetEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
		
		TimeSeriesIterator target_iterator = TestingBaseAggregatadQualityQuery(plotID, querySchema, targetStart, targetEnd, dataQuality);
			
		
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
		
			TimeSeriesIterator source_iterator = TestingBaseAggregatadQualityQuery(sourceStation.plotID, querySchema, interpolationStartTimestamp , interpolationEndTimestamp, dataQuality);
			
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
		
		//return targetTimeSeries.getClipped(queryStart, queryEnd).timeSeriesIterator();
		
		return targetTimeSeries.timeSeriesIteratorCLIP(queryStart, queryEnd);
		
		
		
	}
	
	
	public TimeSeriesIterator TestingInterpolatedAggregatadQualityQuery(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval) {
		//TimeSeriesIterator baseAggregatedQualityIterator = TestingBaseAggregatadQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality);
		TimeSeriesIterator input_iterator = TestingInterpolatedBaseAggregatadQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality);
			
		return new AggregationIterator(timeSeriesDatabase, input_iterator, aggregationInterval);		
	}
	
	public TimeSeriesIterator TestingAggregatadQualityQuery(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) {
		if(interpolated) {
			return TestingInterpolatedAggregatadQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		} else {
			return TestingAggregatadQualityQuery(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval);
		}
	}
	
	
	
	
	

}
