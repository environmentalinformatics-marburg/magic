package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.iterator.AggregationIterator;
import util.iterator.TimeSeriesIterator;

public class Aggregated extends Node {
	
	private final Node source;
	private final AggregationInterval aggregationInterval;

	protected Aggregated(TimeSeriesDatabase timeSeriesDatabase, Node source, AggregationInterval aggregationInterval) {
		super(timeSeriesDatabase);
		this.source = source;
		this.aggregationInterval = aggregationInterval;
		if(!source.isContinuous()) {
			throw new RuntimeException("source needs to be continuous");
		}
	}
	
	public static Aggregated create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, AggregationInterval aggregationInterval) {
		Continuous node = Continuous.create(timeSeriesDatabase, stationName, querySchema);		
		return new Aggregated(timeSeriesDatabase, node, aggregationInterval);
	}
	
	public static Aggregated create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, AggregationInterval aggregationInterval, DataQuality dataQuality) {
		Continuous node = Continuous.create(timeSeriesDatabase, stationName, querySchema, dataQuality);		
		return new Aggregated(timeSeriesDatabase, node, aggregationInterval);
	}
	
	public static Aggregated createInterpolated(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, AggregationInterval aggregationInterval) {
		Node node = Interpolated.create(timeSeriesDatabase, stationName, querySchema);		
		return new Aggregated(timeSeriesDatabase, node, aggregationInterval);
	}
	
	public static Aggregated createInterpolated(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, AggregationInterval aggregationInterval, DataQuality dataQuality) {
		Node node = Interpolated.create(timeSeriesDatabase, stationName, querySchema, dataQuality);		
		return new Aggregated(timeSeriesDatabase, node, aggregationInterval);
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
	public boolean isContinuous() {
		return true;
	}
}
