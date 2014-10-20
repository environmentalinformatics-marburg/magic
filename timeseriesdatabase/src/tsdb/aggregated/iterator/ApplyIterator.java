package tsdb.aggregated.iterator;

import java.util.function.Function;

import tsdb.raw.TsEntry;
import tsdb.util.iterator.InputIterator;
import tsdb.util.iterator.TsIterator;

public class ApplyIterator extends InputIterator {

	private final Function<TsEntry,TsEntry> function;

	public ApplyIterator(TsIterator input_iterator, Function<TsEntry,TsEntry> function) {
		super(input_iterator, input_iterator.getSchema().copy());
		this.function = function;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TsEntry next() {
		return function.apply(input_iterator.next());
	}
}
