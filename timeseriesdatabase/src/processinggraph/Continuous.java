package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class Continuous extends Node {
	
	private final Base source;

	protected Continuous(TimeSeriesDatabase timeSeriesDatabase, Base source) {
		super(timeSeriesDatabase);
		this.source = source;
	}

	public static Continuous create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema) {
		Base node = Base.create(timeSeriesDatabase, stationName, querySchema);
		return new Continuous(timeSeriesDatabase, node);
	}
	
	public static Continuous create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, DataQuality dataQuality) {
		Base node = Base.create(timeSeriesDatabase, stationName, querySchema, dataQuality);
		return new Continuous(timeSeriesDatabase, node);
	}
	
	public static Continuous createFromBase(TimeSeriesDatabase timeSeriesDatabase, Base base) {
		return new Continuous(timeSeriesDatabase, base);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		if(start!=null&&!BaseAggregationTimeUtil.isBaseAggregationTimestamp(start)) {
			log.warn("start timestamp not alligned: "+start);
			start = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(start); // TODO ?
		}
		if(end!=null&&!BaseAggregationTimeUtil.isBaseAggregationTimestamp(end)) {
			log.warn("end timestamp not alligned: "+end);
			end = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(end); // TODO ?
		}
		NanGapIterator continuous = new NanGapIterator(input_iterator, start, end);
		if(!continuous.hasNext()) {
			return null;
		}
		return continuous;
	}
	
	public TimeSeriesIterator getExactly(long start, long end) {		
		return get(start,end);
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public boolean isContinuous() {
		return true;
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}	
}
