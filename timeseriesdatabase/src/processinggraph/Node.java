package processinggraph;

import java.util.Iterator;

import org.apache.logging.log4j.Logger;


import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Util;
import util.iterator.TimeSeriesIterator;

public abstract class Node implements Iterable<TimeSeriesEntry> {
	
	protected static final Logger log = Util.log;
	
	protected final TimeSeriesDatabase timeSeriesDatabase;
	public Node(TimeSeriesDatabase timeSeriesDatabase) {
		this.timeSeriesDatabase = timeSeriesDatabase;
	}

	@Override
	final public Iterator<TimeSeriesEntry> iterator() {
		return get(null,null);
	}
	
	public abstract TimeSeriesIterator get(Long start, Long end);
	
	public abstract Station getSourceStation();
	
	public void writeCSV(Long start, Long end, String filename) {
		get(start,end).writeCSV(filename);
	}
	
	public void writeConsole(Long start, Long end) {
		get(start,end).writeConsole();
	}
	
	public abstract boolean isContinuous();
}
