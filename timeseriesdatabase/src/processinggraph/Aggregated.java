package processinggraph;

import java.util.function.Function;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class Aggregated extends Continuous_temp.Abstract {

	private final Continuous_temp source; //not null
	private final AggregationInterval aggregationInterval; //not null

	protected Aggregated(TimeSeriesDatabase timeSeriesDatabase, Continuous_temp source, AggregationInterval aggregationInterval) {
		super(timeSeriesDatabase);
		Util.throwNull(source,aggregationInterval);
		this.source = source;
		this.aggregationInterval = aggregationInterval;		
		if(!source.isContinuous()) {
			throw new RuntimeException("source needs to be continuous");
		}
	}

	public static Aggregated create(TimeSeriesDatabase timeSeriesDatabase, Continuous_temp source, AggregationInterval aggregationInterval) {
		return new Aggregated(timeSeriesDatabase, source, aggregationInterval);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		TimeSeriesIterator continuous_iterator = source.get(start, end);
		if(continuous_iterator==null||!continuous_iterator.hasNext()) {
			return null;
		}
		AggregationIterator aggregation_iterator = new AggregationIterator(timeSeriesDatabase, continuous_iterator, aggregationInterval);
		if(aggregation_iterator==null||!aggregation_iterator.hasNext()) {
			return null;
		}
		return aggregation_iterator;
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

	@Override
	public TimeSeriesIterator getExactly(long start, long end) {
		return get(start, end);
	}

	@Override
	public boolean isContinuous() {
		return true;
	}	

	@Override
	public boolean isConstantTimestep() {
		switch(aggregationInterval) {
		case HOUR:
		case DAY:
		case WEEK:
			return true;
		case MONTH:
		case YEAR:
			return false;
		default:
			throw new RuntimeException("unknown aggregation interval");	
		}
	}
}
