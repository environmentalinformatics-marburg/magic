package processinggraph;

import timeseriesdatabase.TimeSeriesDatabase;
import util.iterator.TimeSeriesIterator;

public class Interpolated extends Node {
	
	Node source;

	public Interpolated(TimeSeriesDatabase timeSeriesDatabase, Node source) {
		super(timeSeriesDatabase);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public boolean isContinuous() {
		// TODO Auto-generated method stub
		return false;
	}

}
