package util.iterator;

import java.util.Iterator;
import java.util.List;

import util.OutputSchema;
import util.ProcessingChain;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;

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
