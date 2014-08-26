package tsdb.graph;

import java.util.function.Function;

import tsdb.DataQuality;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.aggregated.AggregationType;
import tsdb.aggregated.iterator.AggregationIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class Aggregated extends Continuous.Abstract {

	private final Continuous source; //not null
	private final AggregationInterval aggregationInterval; //not null

	protected Aggregated(TsDB tsdb, Continuous source, AggregationInterval aggregationInterval) {
		super(tsdb);
		Util.throwNull(source,aggregationInterval);
		this.source = source;
		this.aggregationInterval = aggregationInterval;		
		if(!source.isContinuous()) {
			throw new RuntimeException("source needs to be continuous");
		}
	}

	public static Aggregated create(TsDB tsdb, Continuous source, AggregationInterval aggregationInterval) {
		return new Aggregated(tsdb, source, aggregationInterval);
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
