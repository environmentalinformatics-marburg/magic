package util;

import java.util.Iterator;

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
