package timeseriesdatabase.aggregated.iterator;

import java.util.List;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.iterator.MoveIterator;
import util.iterator.TimeSeriesIterator;

/**
 * Sends only input elements that have at least one not NaN-value.
 * @author woellauer
 *
 */
public class NanRemoveIterator extends MoveIterator{
	
	TimeSeriesIterator input_iterator;

	public NanRemoveIterator(TimeSeriesIterator input_iterator) {
		super(new TimeSeriesSchema(input_iterator.getOutputSchema()));
		this.input_iterator = input_iterator;
	}

	@Override
	protected TimeSeriesEntry getNext() {
		while(input_iterator.hasNext()) {
			TimeSeriesEntry next = input_iterator.next();
			int counter = 0;
			for(float v:next.data) {
				if(!Float.isNaN(v)) {
					counter++;
				}
			}
			if(counter>0) {
				return next;
			}
		}
		return null;
	}

	@Override
	public String getIteratorName() {
		return "NanGapIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}

}
