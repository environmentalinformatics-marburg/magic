package tsdb.util.iterator;

import tsdb.util.TsEntry;
import tsdb.util.TsSchema;

public abstract class MoveIterator extends TsIterator {

	private TsEntry current = null;
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
	public final TsEntry next() {
		hasNext();
		TsEntry result = current;
		current = null;
		hasNext();
		return result;
	}

	protected abstract TsEntry getNext();

}
