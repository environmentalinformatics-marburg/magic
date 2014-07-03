package util.iterator;

import timeseriesdatabase.raw.TimestampSeriesEntry;
import util.TimeSeriesSchema;

public abstract class TimeSeriesIterator extends SchemaIterator<TimestampSeriesEntry> {

	public TimeSeriesIterator(TimeSeriesSchema outputTimeSeriesSchema) {
		super(outputTimeSeriesSchema);
	}

}
