package util.iterator;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;

public class TimeSeriesEntryIterator extends TimeSeriesIterator {
	
	private Iterator<TimeSeriesEntry> input_iterator;

	public TimeSeriesEntryIterator(Iterator<TimeSeriesEntry> input_iterator, String[] schema) {
		super(new TimeSeriesSchema(schema));
		this.input_iterator = input_iterator;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		return input_iterator.next();
	}

	@Override
	public String getIteratorName() {
		return "TimeSeriesEntryIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = new ArrayList<ProcessingChainEntry>();
		result.add(this);
		return result;
	}

}
