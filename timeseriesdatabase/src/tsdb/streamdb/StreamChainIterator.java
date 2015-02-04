package tsdb.streamdb;

import java.util.Iterator;
import java.util.List;

import tsdb.TimeConverter;

public class StreamChainIterator implements Iterator<DataEntry>{
	
	private final Iterator<StreamIterator> itit;
	private StreamIterator current;

	public StreamChainIterator(List<StreamIterator> iterators) {
		if(iterators.isEmpty()) {
			throw new RuntimeException();
		}
		int prev = 0;
		for(StreamIterator it:iterators) {
			if(it.minQueryTimestamp<=prev) {
				throw new RuntimeException("StreamChainIterator: prev timestamp greater or equal to new min timestamp:"+TimeConverter.oleMinutesToText((long) prev)+"  "+TimeConverter.oleMinutesToText((long) it.minQueryTimestamp)+"  "+it.stationName+" of "+it.sensorName);
			}
			if(it.minQueryTimestamp>it.maxQueryTimestamp) {
				throw new RuntimeException();
			}
			prev = it.maxQueryTimestamp;
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
