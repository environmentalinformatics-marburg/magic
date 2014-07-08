package util;

public class TimeSeriesSchema {
	
	/**
	 * sensor names in order of columns in data rows
	 */
	public final String[] schema;
	
	/**
	 * if entries are aggregated data with constant time seps, may contain gaps
	 */
	public final boolean constantTimeStep;
	public final int timeStep;
	
	public final int columns;
	
	public final boolean isContinuous;
	
	//TODO special meta data
	//public final boolean hasQualityFlags;
	//public final boolean hasInterpolatedFlags;
	//public final boolean hasQualityCounters;

	
	public TimeSeriesSchema(String[] schema) {
		this.schema = schema;
		this.constantTimeStep = false;
		this.timeStep = -999999;
		this.columns = schema.length;
		this.isContinuous = false;
		
	}
	
	public TimeSeriesSchema(String[] schema, int timeStep) {
		this.schema = schema;
		this.constantTimeStep = true;
		this.timeStep = timeStep;
		this.columns = schema.length;
		this.isContinuous = false;
	}
	
	public TimeSeriesSchema(String[] schema, int timeStep, boolean isContinuous) {
		this.schema = schema;
		this.constantTimeStep = true;
		this.timeStep = timeStep;
		this.columns = schema.length;
		this.isContinuous = isContinuous;
	}
	
	

}
