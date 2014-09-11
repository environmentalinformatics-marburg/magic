package tsdb.util;

import java.util.Iterator;
import java.util.function.Function;
import java.util.function.Supplier;

import tsdb.DataQuality;
import tsdb.QueryProcessor;
import tsdb.aggregated.iterator.ApplyIterator;
import tsdb.aggregated.iterator.LinearIterpolationIterator;
import tsdb.aggregated.iterator.NanGapIterator;
import tsdb.aggregated.iterator.ProjectionIterator;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import tsdb.util.iterator.TsIterator;

/**
 * Builder creates a Factory to create a chain of TimeseriesIterators
 * @author woellauer
 *
 */
public class Builder implements Iterable<TimeSeriesEntry> {
	
	public static Builder base_aggregated(QueryProcessor qp, String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		return new Builder(()->qp.query_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality), queryStart, queryEnd);
	}
	
	public static Builder continuous_base_aggregated(QueryProcessor qp, String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality) {
		return new Builder(()->qp.query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality), queryStart, queryEnd);
	}
	
	public static TsIterator project(TsIterator it, String ... schema) {
		return new ProjectionIterator(it,schema);
	}
	
	public static TsIterator project(TsIterator it, TsIterator targetSchema) {
		return project(it, targetSchema.getNames());
	}
	
	public static TsIterator continuous(TsIterator it) {
		return new NanGapIterator(it,null,null);
	}
	
	public static TsIterator continuous(TsIterator it, Long start, Long end) {
		return new NanGapIterator(it,start,end);
	}
	
	public static TsIterator apply(TsIterator it, Function<TimeSeriesEntry,TimeSeriesEntry> mapper) {
		return new ApplyIterator(it,mapper);
	}
	
	public static TsIterator linearIterpolate(TsIterator it) {
		return new LinearIterpolationIterator(it);
	}
	
	private final Supplier<TsIterator> supplier;
	
	/*public Builder(Supplier<TimeSeriesIterator> supplier) {
		this.supplier = supplier;
		this.queryStart = null;
		this.queryEnd = null;
	}*/
	
	public Builder(Supplier<TsIterator> supplier, Long queryStart, Long queryEnd) {
		this.supplier = supplier;
		this.queryStart = queryStart;
		this.queryEnd = queryEnd;
	}
	
	public TsIterator create() {
		return supplier.get();
	}
	
	@Override
	public Iterator<TimeSeriesEntry> iterator() {
		return create();
	}
	
	//**************************************************************************
	
	public final Long queryStart;
	public final Long queryEnd;
	
	/**
	 * Project schema to new schema
	 * @param schema
	 * @return
	 */
	public Builder project(String ... schema) {
		return new Builder(()->project(this.create(),schema),this.queryStart,this.queryEnd);
	}
	
	/**
	 * Project schema to schema of target_iterator
	 * @param target_iterator
	 * @return
	 */
	public Builder project(TsIterator target_iterator) {
		return new Builder(()->project(this.create(),target_iterator),this.queryStart,this.queryEnd);
	}
	
	/**
	 * Fill gaps in time with nan rows.
	 * @param start
	 * @param end
	 * @return
	 */
	public Builder continuous(Long start, Long end) {
		return new Builder(()->continuous(this.create(),start,end),start,end);
	}
	
	/**
	 * Fill gaps in time with nan rows.
	 * @param start
	 * @param end
	 * @return
	 */
	public Builder continuous() {
		return new Builder(()->continuous(this.create(),this.queryStart,this.queryEnd),this.queryStart,this.queryEnd);
	}
	
	/**
	 * Apply to each TimeSeriesEntry a mapper function.
	 * @param mapper
	 * @return
	 */
	public Builder apply(Function<TimeSeriesEntry,TimeSeriesEntry> mapper) {
		return new Builder(()->apply(this.create(),mapper),this.queryStart,this.queryEnd);
	}
	
	/**
	 * Interpolate one value gaps in time series with Average between previous and next value.
	 * @return
	 */
	public Builder linearInterpolate() {
		return new Builder(()->linearIterpolate(this.create()),this.queryStart,this.queryEnd);
	}
	
	/**
	 * Write output to CSV-File
	 * @param filename
	 */
	public void writeCSV(String filename) {
		this.create().writeCSV(filename);
	}
	
	public TimestampSeries createTimestampSeries() {
		return Util.ifnull(this.create(), it->TimestampSeries.create(it));
	}


	
	

}
