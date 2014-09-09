package tsdb.graph;

import tsdb.Station;
import tsdb.TsDB;
import tsdb.TsDBClient;
import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.aggregated.iterator.NanGapIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public interface Continuous extends Node {
	
	@Override
	public default boolean isContinuous() {
		return true;
	}
	
	public TimeSeriesIterator getExactly(long start, long end);
	
	public static Continuous create(TsDB tsdb, Base base) {
		return new Concrete(tsdb, base);
	}
	
	public abstract class Abstract extends TsDBClient implements Continuous {
		protected Abstract(TsDB tsdb) {
			super(tsdb);
		}	
	}
	
	public class Concrete extends Abstract {
		private final Base source;
		protected Concrete(TsDB tsdb, Base source) {
			super(tsdb); 
			Util.throwNull(source);
			this.source = source;
			if(!source.isConstantTimestep()) {
				throw new RuntimeException("source with no constant timestep");
			}
		}		

		@Override
		public TimeSeriesIterator get(Long start, Long end) {
			TimeSeriesIterator input_iterator = source.get(start, end);
			if(input_iterator==null||!input_iterator.hasNext()) {
				return null;
			}
			if(start!=null&&!BaseAggregationTimeUtil.isBaseAggregationTimestamp(start)) {
				log.warn("start timestamp not alligned: "+start);
				start = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(start); // TODO ?
			}
			if(end!=null&&!BaseAggregationTimeUtil.isBaseAggregationTimestamp(end)) {
				log.warn("end timestamp not alligned: "+end);
				end = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(end); // TODO ?
			}
			NanGapIterator continuous = new NanGapIterator(input_iterator, start, end);
			if(!continuous.hasNext()) {
				return null;
			}
			return continuous;
		}
		
		@Override
		public TimeSeriesIterator getExactly(long start, long end) {		
			return get(start,end);
		}

		@Override
		public Station getSourceStation() {
			return source.getSourceStation();
		}

		@Override
		public String[] getSchema() {
			return source.getSchema();
		}

		@Override
		public boolean isConstantTimestep() {
			return true;
		}

	
	}
}
