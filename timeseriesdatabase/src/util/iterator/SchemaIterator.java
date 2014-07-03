package util.iterator;

import java.util.Iterator;

import util.OutputSchema;
import util.TimeSeriesSchema;

public abstract class SchemaIterator<T> implements Iterator<T>, OutputSchema {
	
	protected TimeSeriesSchema outputTimeSeriesSchema;

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
