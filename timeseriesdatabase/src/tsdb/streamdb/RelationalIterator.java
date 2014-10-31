package tsdb.streamdb;

import java.util.Arrays;

import tsdb.raw.TsEntry;
import tsdb.util.AssumptionCheck;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class RelationalIterator extends TsIterator {

	private StreamIterator[] iterators;
	private TsEntry curr;
	private DataEntry[] next;
	private int[] posIndex;

	public RelationalIterator(StreamIterator[] iterators, String[] outputSchema) {
		super(new TsSchema(outputSchema));	
		this.iterators = iterators;
		String[] inputSchema = Arrays.stream(iterators).map(it->it.sensorName).toArray(String[]::new);
		AssumptionCheck.throwNotContained(inputSchema,outputSchema);
		posIndex = Util.stringArrayToPositionIndexArray(outputSchema, inputSchema, false, false);
		next = new DataEntry[iterators.length];		
		for(int i=0;i<iterators.length;i++) {
			if(iterators[i].hasNext()) {
				next[i] = iterators[i].next(); 
			} else {
				next[i] = null;
			}				
		}
		calcNext();
	}

	private void calcNext() {
		int timestamp = Integer.MAX_VALUE;
		for(int i=0;i<iterators.length;i++) {
			if(next[i]!=null&&next[i].timestamp<timestamp) {
				timestamp = next[i].timestamp;
			}
		}
		if(timestamp==Integer.MAX_VALUE) {
			curr = null;
		} else {
			float[] data = new float[schema.length];
			for(int i=0;i<schema.length;i++) {
				final int pos = posIndex[i];
				if(pos!=-1&&next[pos].timestamp==timestamp) {
					data[i] = next[pos].value;
					if(iterators[pos].hasNext()) {
						next[pos] = iterators[pos].next();
					} else {
						next[pos] = null;
					}
				} else {
					data[i] = Float.NaN;
				}
			}
			curr = new TsEntry(timestamp, data);
		}
	}

	@Override
	public boolean hasNext() {
		return curr!=null;
	}

	@Override
	public TsEntry next() {
		TsEntry r = curr;
		calcNext();
		return r;
	}

}
