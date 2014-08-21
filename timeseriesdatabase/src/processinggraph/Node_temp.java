package processinggraph;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import util.Util;
import util.iterator.TimeSeriesIterator;

public interface Node_temp {
	
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
	
	public abstract class Abstract implements Node_temp {
		
		protected final TimeSeriesDatabase timeSeriesDatabase; //not null
		
		Abstract(TimeSeriesDatabase timeSeriesDatabase) {
			Util.throwNull(timeSeriesDatabase);
			this.timeSeriesDatabase = timeSeriesDatabase;
		}
	}
}
