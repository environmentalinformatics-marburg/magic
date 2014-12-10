package tsdb.streamdb;

import java.util.Iterator;
import java.util.List;

public class StreamChainIterator implements Iterator<DataEntry>{
	
	private final Iterator<StreamIterator> itit;
	private StreamIterator current;

	public StreamChainIterator(List<StreamIterator> iterators) {
		if(iterators.isEmpty()) {
			throw new RuntimeException();
		}
		int prev = 0;
		for(StreamIterator it:iterators) {
			if(it.minTimestamp<=prev) {
				throw new RuntimeException();
			}
			if(it.minTimestamp>it.maxTimestamp) {
				throw new RuntimeException();
			}
			prev = it.maxTimestamp;
		}
		itit = iterators.iterator();
		current = itit.next();
	}

	@Override
	public boolean hasNext() {
		while(!current.hasNext()) {
			if(!itit.hasNext()) {
				return false;
			}
			current = itit.next();
		}
		return true;
	}

	@Override
	public DataEntry next() {
		return current.next();
	}

}
