package tsdb.graph;

import tsdb.Station;
import tsdb.aggregated.iterator.PeakSmoothIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class PeakSmoothed implements Base {
	
	private Node source;

	protected PeakSmoothed(Node source) {
		Util.throwNull(source);
		this.source = source;
	}
	
	public static PeakSmoothed create(Node source) {
		return new PeakSmoothed(source);
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
