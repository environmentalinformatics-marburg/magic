package util.iterator;

import java.util.List;

import util.ProcessingChainEntry;
import util.TimeSeriesSchema;

/**
 * Base class for iterators that process input from one TimeSeriesIterator
 * @author woellauer
 *
 */
public abstract class InputProcessingIterator extends MoveIterator {
	
	protected final TimeSeriesIterator input_iterator;

	public InputProcessingIterator(TimeSeriesIterator input_iterator, TimeSeriesSchema output_schema) {
		super(output_schema);
		this.input_iterator = input_iterator;
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}
}
