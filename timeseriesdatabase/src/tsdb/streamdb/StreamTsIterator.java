package tsdb.streamdb;

import tsdb.raw.TsEntry;
import tsdb.util.TsSchema;
import tsdb.util.iterator.TsIterator;

public class StreamTsIterator extends TsIterator {
	
	private final StreamIterator input_iterator;
	
	public StreamTsIterator(StreamIterator input_iterator) {
		super(new TsSchema(new String[]{input_iterator.sensorName}));
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
