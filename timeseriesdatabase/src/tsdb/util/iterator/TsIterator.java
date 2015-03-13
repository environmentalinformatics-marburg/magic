package tsdb.util.iterator;

import java.util.Arrays;
import java.util.Iterator;

import tsdb.util.ProcessingChainEntry;
import tsdb.util.TsEntry;
import tsdb.util.TsSchema;

public abstract class TsIterator implements Iterator<TsEntry>, ProcessingChainEntry {

	protected final TsSchema schema;
	
	public TsIterator(TsSchema schema) {
		this.schema = schema;
	}
	
	public TsSchema getSchema() {
		return schema;
	}

	public String[] getNames() {
		return schema.names;
	}
	
	@Override
	public String getProcessingTitle() {
		String simpleName = this.getClass().getSimpleName();
		if(simpleName.isEmpty()) {
			return this.getClass().getName();
		}
		return simpleName;
	}
	
	public ProcessingChain getProcessingChain() {
		return new ProcessingChainSource(this);
	}
	
	@Override
	public String toString() {		
		return getProcessingTitle()+" "+schema.toString()+" "+getProcessingChain().getText();
	}	
	
	public void writeCSV(String filename) {
		CSV.write(this,filename);
	}
	
	public void writeConsole() {
		while(this.hasNext()) {
			TsEntry e = this.next();
			System.out.println(e);
		}		
	}
	
	public TimeSeries toTimeSeries() {
		return TimeSeries.create(this);
	}
	
	public TimestampSeries toTimestampSeries(String name) {
		return TimestampSeries.create(this,name);
	}
	
	public static TsSchema[] toSchemas(TsIterator[] input_iterators) {
		return Arrays.stream(input_iterators).map(it->it.getSchema()).toArray(TsSchema[]::new);
	}
}
