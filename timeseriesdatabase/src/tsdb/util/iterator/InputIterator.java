package tsdb.util.iterator;

import java.util.List;

import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsSchema;

/**
 * Base class for iterators that process input from one TimeSeriesIterator
 * @author woellauer
 *
 */
public abstract class InputIterator extends TsIterator {
	
	protected final TsIterator input_iterator;

	public InputIterator(TsIterator input_iterator, TsSchema output_schema) {
		super(output_schema);
		this.input_iterator = input_iterator;
	}

	@Override
	public NewProcessingChain getProcessingChain() {		
		return new NewProcessingChainOneSource(input_iterator,this);
	}

	
}
