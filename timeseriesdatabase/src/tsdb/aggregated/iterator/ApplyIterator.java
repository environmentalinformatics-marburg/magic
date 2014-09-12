package tsdb.aggregated.iterator;

import java.util.function.Function;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.iterator.InputIterator;
import tsdb.util.iterator.TsIterator;

public class ApplyIterator extends InputIterator {

	private final Function<TimeSeriesEntry,TimeSeriesEntry> function;

	public ApplyIterator(TsIterator input_iterator, Function<TimeSeriesEntry,TimeSeriesEntry> function) {
		super(input_iterator, input_iterator.getSchema().copy());
		this.function = function;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		return function.apply(input_iterator.next());
	}
}
