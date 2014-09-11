package tsdb.util.iterator;

import java.util.List;

import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.Util;

public class SchemaConverterIterator extends MoveIterator {

	private TsIterator input_iterator;
	private int[] inputPos;

	public SchemaConverterIterator(TsIterator input_iterator, String[] outputSchema, boolean fillWithNaN) {
		super(new TimeSeriesSchema(outputSchema).toTsSchema());
		this.input_iterator = input_iterator;
		this.inputPos = Util.stringArrayToPositionIndexArray(outputSchema, input_iterator.getNames(), !fillWithNaN, false);
	}

	@Override
	protected TimeSeriesEntry getNext() {
		if(input_iterator.hasNext()) {
			TimeSeriesEntry e = input_iterator.next();
			float[] data = new float[inputPos.length];
			for(int i=0;i<data.length;i++) {
				int pos = inputPos[i];
				if(pos==-1) {
					data[i] = Float.NaN;
				} else {
					data[i] = e.data[pos];
				}					
			}
			return new TimeSeriesEntry(e.timestamp,data);
		} else {
			return null;
		}
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}

}