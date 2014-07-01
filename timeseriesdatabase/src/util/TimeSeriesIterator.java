package util;

import timeseriesdatabase.raw.TimestampSeriesEntry;

public abstract class TimeSeriesIterator extends SchemaIterator<TimestampSeriesEntry> {

	public TimeSeriesIterator(TimeSeriesSchema outputTimeSeriesSchema) {
		super(outputTimeSeriesSchema);
	}

}
