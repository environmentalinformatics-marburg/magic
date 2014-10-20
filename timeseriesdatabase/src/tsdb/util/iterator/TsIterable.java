package tsdb.util.iterator;

import java.util.Iterator;

import tsdb.raw.TsEntry;

public interface TsIterable extends Iterable<TsEntry> {

	@Override
	public default Iterator<TsEntry> iterator() {
		return tsIterator();
	}
	
	public TsIterator tsIterator();

}
