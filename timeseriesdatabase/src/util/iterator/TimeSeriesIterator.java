package util.iterator;

import timeseriesdatabase.raw.TimeSeriesEntry;
import util.TimeSeriesSchema;

public abstract class TimeSeriesIterator extends SchemaIterator<TimeSeriesEntry> {

	public TimeSeriesIterator(TimeSeriesSchema outputTimeSeriesSchema) {
		super(outputTimeSeriesSchema);
	}

}
