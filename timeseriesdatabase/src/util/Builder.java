package util;

import java.util.function.Function;

import timeseriesdatabase.aggregated.iterator.ApplyIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.aggregated.iterator.ProjectionIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.iterator.TimeSeriesIterator;

public class Builder {
	
	public static TimeSeriesIterator project(TimeSeriesIterator it, String ... schema) {
		return new ProjectionIterator(it,schema);
	}
	
	public static TimeSeriesIterator project(TimeSeriesIterator it, TimeSeriesIterator targetSchema) {
		return project(it, targetSchema.getOutputSchema());
	}
	
	public static TimeSeriesIterator fill(TimeSeriesIterator it, Long start, Long end) {
		return new NanGapIterator(it,start,end);
	}
	
	public static TimeSeriesIterator apply(TimeSeriesIterator it, Function<TimeSeriesEntry,TimeSeriesEntry> mapper) {
		return new ApplyIterator(it,mapper);
	}
	
	

}
