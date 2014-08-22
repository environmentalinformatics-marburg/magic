package processinggraph;

import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.iterator.BaseAggregationIterator;
import timeseriesdatabase.aggregated.iterator.PeakSmoothIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class PeakSmoothed extends Base.Abstract {
	
	private Node source;

	protected PeakSmoothed(TimeSeriesDatabase timeSeriesDatabase, Node source) {
		super(timeSeriesDatabase);
		Util.throwNull(source);
		this.source = source;
	}
	
	public static PeakSmoothed create(TimeSeriesDatabase timeSeriesDatabase, Node source) {
		return new PeakSmoothed(timeSeriesDatabase, source);
	}	

	@Override
	public TimeSeriesIterator get(Long start, Long end) {		
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		PeakSmoothIterator manual_fill_iterator = new PeakSmoothIterator(input_iterator);
		if(manual_fill_iterator==null||!manual_fill_iterator.hasNext()) {
			return null;
		}
		return manual_fill_iterator;
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public boolean isContinuous() { //TODO
		return false;
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

}
