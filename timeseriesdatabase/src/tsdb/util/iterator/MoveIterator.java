package tsdb.util.iterator;

import java.util.Iterator;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TimeSeriesSchema;

public abstract class MoveIterator extends TimeSeriesIterator {

	private TimeSeriesEntry current = null;
	protected boolean closed = false;
	
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
	public final TimeSeriesEntry next() {
		hasNext();
		TimeSeriesEntry result = current;
		current = null;
		hasNext();
		return result;
	}

	protected abstract TimeSeriesEntry getNext();

}
