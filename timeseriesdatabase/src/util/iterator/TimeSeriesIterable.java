package util.iterator;

import java.util.Iterator;

import timeseriesdatabase.raw.TimestampSeriesEntry;

public interface TimeSeriesIterable extends Iterable<TimestampSeriesEntry> {

	@Override
	public default Iterator<TimestampSeriesEntry> iterator() {
		return timeSeriesIterator();
	}
	
	public TimeSeriesIterator timeSeriesIterator();

}
