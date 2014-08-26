package tsdb.util;

public interface OutputSchema {	
	public TimeSeriesSchema getOutputTimeSeriesSchema();
	public String[] getOutputSchema();
}
