package util;

import java.util.Iterator;

import timeseriesdatabase.raw.TimestampSeriesEntry;

public abstract class MoveIterator extends TimeSeriesIterator {

	private TimestampSeriesEntry current = null;
	private boolean closed = false;
	
	public MoveIterator(TimeSeriesSchema outputTimeSeriesSchema) {
		super(outputTimeSeriesSchema);
	}

	@Override
	public final boolean hasNext() {
		if(closed) {
			return false;
		} else {
			if(current==null) {
				current = getNext();
				if(current==null) {
					closed=true;
					return false;
				} 
			}				
		}
		return true;
	}

	@Override
	public final TimestampSeriesEntry next() {
		hasNext();
		TimestampSeriesEntry result = current;
		current = null;
		hasNext();
		return result;
	}

	protected abstract TimestampSeriesEntry getNext();

}
