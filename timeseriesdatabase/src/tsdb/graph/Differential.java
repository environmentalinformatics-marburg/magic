package tsdb.graph;

import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.iterator.DifferentialIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class Differential extends Continuous.Abstract {
	
	private Continuous source;

	protected Differential(TsDB tsdb, Continuous source) {
		super(tsdb);
		Util.throwNull(source);
		this.source = source;
	}
	
	public static Differential create(TsDB tsdb, Continuous source) {
		return new Differential(tsdb, source);
	}

	@Override
	public TimeSeriesIterator getExactly(long start, long end) {
		return get(start, end);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {		
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}		
		DifferentialIterator it = new DifferentialIterator(input_iterator);
		if(it==null||!it.hasNext()) {
			return null;
		}
		return it;
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public boolean isContinuous() {
		return source.isContinuous();
	}

	@Override
	public boolean isConstantTimestep() {
		return source.isConstantTimestep();
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

}
