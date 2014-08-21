package processinggraph;

import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.iterator.BaseAggregationIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class StationBase extends Base.Abstract {

	private final Node_temp source;	

	protected StationBase(TimeSeriesDatabase timeSeriesDatabase, Node_temp source) {
		super(timeSeriesDatabase);
		Util.throwNull(source);
		this.source = source;
	}

	public static StationBase create(TimeSeriesDatabase timeSeriesDatabase,Station station, String[] querySchema, NodeGen stationGen) {
		if(querySchema==null) {
			querySchema = timeSeriesDatabase.getBaseAggregationSchema(station.loggerType.sensorNames);
		}
		Node_temp source = stationGen.get(station.stationID, querySchema);
		return new StationBase(timeSeriesDatabase, source);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		BaseAggregationIterator base_iterator = new BaseAggregationIterator(timeSeriesDatabase, input_iterator);
		if(!base_iterator.hasNext()) {
			return null;
		}	

		return base_iterator;				
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public boolean isContinuous() {
		return false; // maybe todo
	}

	@Override
	public String[] getSchema() {
		return timeSeriesDatabase.getBaseAggregationSchema(source.getSchema());
	}
}
