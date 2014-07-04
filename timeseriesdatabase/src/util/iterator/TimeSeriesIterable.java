package util.iterator;

import java.util.Iterator;

import timeseriesdatabase.raw.TimeSeriesEntry;

public interface TimeSeriesIterable extends Iterable<TimeSeriesEntry> {

	@Override
	public default Iterator<TimeSeriesEntry> iterator() {
		return timeSeriesIterator();
	}
	
	public TimeSeriesIterator timeSeriesIterator();

}
