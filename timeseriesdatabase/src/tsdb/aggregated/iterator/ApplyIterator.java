package tsdb.aggregated.iterator;

import java.util.List;
import java.util.function.Function;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsSchema;
import tsdb.util.iterator.NewProcessingChainOneSource;
import tsdb.util.iterator.TsIterator;

public class ApplyIterator extends TsIterator {

	private final TsIterator input_iterator;
	private final Function<TimeSeriesEntry,TimeSeriesEntry> function;

	public ApplyIterator(TsIterator input_iterator, Function<TimeSeriesEntry,TimeSeriesEntry> function) {
		super(input_iterator.getSchema().copy());
		this.input_iterator = input_iterator;
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

	@Override
	public NewProcessingChainOneSource getProcessingChain() {
		return new NewProcessingChainOneSource(input_iterator,this);
	}
}
