package tsdb.streamdb;

import java.util.Arrays;
import java.util.Collection;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.raw.TsEntry;
import tsdb.util.AssumptionCheck;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class RelationalIterator extends TsIterator {
	private static final Logger log = LogManager.getLogger();

	private StreamIterator[] iterators;
	private TsEntry curr;
	private DataEntry[] next;
	private int[] posIndex;

	private float[] NAN_DATA;

	public RelationalIterator(Collection<StreamIterator> iterators, String[] outputSchema) {
		this(iterators.toArray(new StreamIterator[0]),outputSchema);
	}

	public RelationalIterator(StreamIterator[] iterators, String[] outputSchema) {
		super(new TsSchema(outputSchema));
		this.iterators = iterators;
		Map<String, Integer> outputMap = Util.stringArrayToMap(outputSchema);
		posIndex = new int[iterators.length];
		for(int i=0;i<iterators.length;i++) {
			Integer pos = outputMap.get(iterators[i].sensorName);
			if(pos==null) {
				throw new RuntimeException("input not in output: "+iterators[i].sensorName+"  "+Arrays.toString(outputSchema));
			}
			posIndex[i] = pos;
		}
		NAN_DATA = new float[outputSchema.length];
		for(int i=0;i<outputSchema.length;i++) {
			NAN_DATA[i] = Float.NaN;
		}

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
			return;
		}
		float[] data = Arrays.copyOf(NAN_DATA, NAN_DATA.length);
		for(int i=0;i<iterators.length;i++) {
			DataEntry x = next[i];
			if(x!=null&&x.timestamp==timestamp) {
				//if(!Float.isNaN(x.value)) {
				data[posIndex[i]] = x.value;
				//}
				if(iterators[i].hasNext()) {
					next[i] = iterators[i].next();
				} else {
					next[i] = null;
				}
			}
		}
		curr = new TsEntry(timestamp, data);		
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
