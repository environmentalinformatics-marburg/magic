package util;

import java.util.function.Function;
import java.util.function.Supplier;

import com.sun.xml.internal.messaging.saaj.packaging.mime.util.QEncoderStream;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.aggregated.iterator.ApplyIterator;
import timeseriesdatabase.aggregated.iterator.LinearIterpolationIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.aggregated.iterator.ProjectionIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.iterator.TimeSeriesIterator;

public class Builder {
	
	public static Builder query_continuous_base_aggregated(QueryProcessor qp, String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		return new Builder(()->qp.query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality));
	}
	
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
	
	public static TimeSeriesIterator linearIterpolate(TimeSeriesIterator it) {
		return new LinearIterpolationIterator(it);
	}
	
	private final Supplier<TimeSeriesIterator> supplier;
	
	public Builder(Supplier<TimeSeriesIterator> supplier) {
		this.supplier = supplier;
	}
	
	public TimeSeriesIterator create() {
		return supplier.get();
	}
	
	//**************************************************************************
	
	public Builder project(String ... schema) {
		return new Builder(()->project(this.create(),schema));
	}
	
	public Builder project(TimeSeriesIterator targetSchema) {
		return new Builder(()->project(this.create(),targetSchema));
	}
	
	public Builder fill(Long start, Long end) {
		return new Builder(()->fill(this.create(),start,end));
	}
	
	public Builder apply(Function<TimeSeriesEntry,TimeSeriesEntry> mapper) {
		return new Builder(()->apply(this.create(),mapper));
	}
	
	public Builder linearInterpolate() {
		return new Builder(()->linearIterpolate(this.create()));
	}
	
	public void writeCSV(String filename) {
		CSV.write(this.create(),filename);
	}
	
	

}
