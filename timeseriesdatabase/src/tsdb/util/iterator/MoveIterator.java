package tsdb.util.iterator;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TsSchema;

public abstract class MoveIterator extends TsIterator {

	private TimeSeriesEntry current = null;
	protected boolean closed = false;
	
	public MoveIterator(TsSchema schema) {
		super(schema);
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
