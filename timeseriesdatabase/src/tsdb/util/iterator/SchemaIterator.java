package tsdb.util.iterator;

import java.util.Iterator;

import tsdb.util.OutputSchema;
import tsdb.util.ProcessingChain;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;

public abstract class SchemaIterator<T> implements Iterator<T>, OutputSchema, ProcessingChain, ProcessingChainEntry {
	
	protected final TimeSeriesSchema outputTimeSeriesSchema;

	public SchemaIterator(TimeSeriesSchema outputTimeSeriesSchema) {
		this.outputTimeSeriesSchema = outputTimeSeriesSchema;
	}

	@Override
	public TimeSeriesSchema getOutputTimeSeriesSchema() {
		return outputTimeSeriesSchema;
	}

	@Override
	public String[] getOutputSchema() {
		return outputTimeSeriesSchema.schema;
	}
	
	

}
