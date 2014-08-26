package tsdb.util.iterator;

import java.util.Iterator;

import tsdb.raw.TimeSeriesEntry;

public interface TimeSeriesIterable extends Iterable<TimeSeriesEntry> {

	@Override
	public default Iterator<TimeSeriesEntry> iterator() {
		return timeSeriesIterator();
	}
	
	public TimeSeriesIterator timeSeriesIterator();

}
