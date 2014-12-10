package tsdb.streamdb;

import java.util.Iterator;

import tsdb.raw.TsEntry;
import tsdb.util.TsSchema;
import tsdb.util.iterator.TsIterator;

public class StreamTsIterator extends TsIterator {
	
	private final Iterator<DataEntry> input_iterator;
	
	public StreamTsIterator(StreamIterator input_iterator) {
		this(input_iterator,input_iterator.sensorName);
	}
	
	public StreamTsIterator(Iterator<DataEntry> input_iterator, String sensorName) {
		super(new TsSchema(new String[]{sensorName}));
		this.input_iterator = input_iterator;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TsEntry next() {
		DataEntry e = input_iterator.next();
		return new TsEntry(e.timestamp, new float[]{e.value});
	}

}
