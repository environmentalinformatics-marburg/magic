package tsdb.graph;

import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.TsDB;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public interface Node {
	
	static final Logger log = Util.log;
	
	public TimeSeriesIterator get(Long start, Long end);	
	public Station getSourceStation();
	
	/**
	 * true => no time gaps in data stream, time steps do not need to be constant
	 * @return
	 */
	public boolean isContinuous();
	
	
	/**
	 * data stream aligned to time step
	 * @return
	 */
	public boolean isConstantTimestep();
	
	public String[] getSchema();
	
	public default void writeCSV(Long start, Long end, String filename) {
		get(start,end).writeCSV(filename);
	}	
	public default void writeConsole(Long start, Long end) {
		get(start,end).writeConsole();
	}
	
	public abstract class Abstract implements Node {
		
		protected final TsDB tsdb; //not null
		
		Abstract(TsDB tsdb) {
			Util.throwNull(tsdb);
			this.tsdb = tsdb;
		}
	}
}
