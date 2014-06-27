package util;

import java.util.Iterator;

public abstract class MoveIterator<T> implements Iterator<T> {

	private T current = null;
	private boolean closed = false;

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
	public final T next() {
		hasNext();
		T result = current;
		hasNext();
		return result;
	}

	protected abstract T getNext();

}
