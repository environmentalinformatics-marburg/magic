package timeseriesdatabase;

import java.util.List;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationIterator;
import timeseriesdatabase.aggregated.GapFiller;
import timeseriesdatabase.aggregated.NanGapIterator;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimestampSeriesEntry;
import util.SchemaIterator;
import util.TimeSeriesIterator;
import util.Util;

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

	public TimeSeriesIterator queryQualityChecked(String plotID, String[] querySchema, Long start, Long end, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station!=null) {
			return station.queryQualityChecked(querySchema, start, end, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
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

	public TimeSeries queryBaseAggregatedTimeSeries(String plotID, String[] querySchema, Long start, Long end, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
		Station station = timeSeriesDatabase.stationMap.get(plotID);
		if(station!=null) {
			return station.queryBaseAggregatedTimeSeries(querySchema, start, end, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
		} else {
			return null;
		}	
	}

	public TimeSeries queryGapFilledTimeSeries(String plotID, String[] querySchema, Long queryStart, Long queryEnd, boolean checkPhysicalRange, boolean checkEmpiricalRange,boolean checkStepRange) {
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
		TimeSeries targetTimeSeries = TimeSeries.toBaseTimeSeries(target_iterator);
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
			sourceTimeseries[i] = TimeSeries.toBaseTimeSeries(source_iterator);
		}
		
		String[] interpolationSensorNames = querySchema;
		if(querySchema==null) {
			interpolationSensorNames = station.getLoggerType().sensorNames;
		}

		for(String sensor:interpolationSensorNames) {
			if(timeSeriesDatabase.sensorMap.get(sensor).useGapFilling) {
				GapFiller.process(sourceTimeseries, targetTimeSeries, sensor);
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
			TimeSeries timeSeries = queryGapFilledTimeSeries(plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
			return new AggregationIterator(timeSeriesDatabase, timeSeries.getIterator(), aggregationInterval);
		} else {
			TimeSeriesIterator it = queryBaseAggregated(plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
			it = new NanGapIterator(it, queryStart, queryStart);
			return new AggregationIterator(timeSeriesDatabase, it, aggregationInterval);
		}
	}
}
