package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNull;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.util.iterator.TsIterator;

/**
 * The base interface for all Nodes in the Query Graph.
 * @author woellauer
 *
 */
public interface Node {
	
	public TsIterator get(Long start, Long end);	
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
			throwNull(tsdb);
			this.tsdb = tsdb;
		}
	}
}
