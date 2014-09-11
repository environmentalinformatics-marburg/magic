package tsdb.util.iterator;

import java.util.Iterator;

import tsdb.raw.TimeSeriesEntry;

public interface TsIterable extends Iterable<TimeSeriesEntry> {

	@Override
	public default Iterator<TimeSeriesEntry> iterator() {
		return tsIterator();
	}
	
	public TsIterator tsIterator();

}
