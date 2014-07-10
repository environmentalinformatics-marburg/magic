package util;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public class TimeSeriesSchema {
	
	/**
	 * sensor names in order of columns in data rows
	 */
	public final String[] schema;
	
	/**
	 * if entries are aggregated data with constant time seps, may contain gaps
	 */
	public final boolean constantTimeStep;
	public static final int NO_CONSTANT_TIMESTEP = -999999;
	public final int timeStep;
	
	public final int columns;
	
	public final boolean isContinuous;
	
	//special meta data
	public final boolean hasQualityFlags;
	public final boolean hasInterpolatedFlags;
	public final boolean hasQualityCounters;
	
	
	
	/**
	 * adds hasQualityFlags = true to schema
	 * (and hasQualityCounters =  false)
	 * @param input_schema
	 * @return
	 */
	public static TimeSeriesSchema createWithQualityFlags(TimeSeriesSchema input_schema) {
		if(input_schema.hasQualityFlags) {
			throw new RuntimeException("quality flags already in schema");
		}
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;
		boolean hasQualityFlags = true;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = false;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}
	
	public static TimeSeriesSchema copy(TimeSeriesSchema input_schema) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		boolean isContinuous = input_schema.isContinuous;
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		boolean hasInterpolatedFlags = input_schema.hasInterpolatedFlags;
		boolean hasQualityCounters = input_schema.hasQualityCounters;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters);
	}
	
	public static TimeSeriesSchema createJustSchema(String[] schema) {
		boolean constantTimeStep = false;
		int timeStep = NO_CONSTANT_TIMESTEP;
		boolean isContinuous = false;
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false;
		boolean hasQualityCounters = false;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters);

	}
	
	public boolean checkConsistency() {
		if(schema==null) {
			return false;
		}
		if(schema.length<1) {
			return false;
		}
		if(schema.length!=columns) {
			return false;
		}
		Set<String> set = new HashSet<String>();
		for(int i=0;i<schema.length;i++) {
			if(schema[i]==null&&schema[i].isEmpty()) {
				return false;
			}
			if(set.contains(schema[i])) {
				return false;
			}
			set.add(schema[i]);
		}
		if(constantTimeStep) {
			if(timeStep<1) {
				return false;
			}
		} else if(timeStep!=NO_CONSTANT_TIMESTEP){
			return false;
		}
		if(isContinuous&&!constantTimeStep) {
			return false;
		}
		return true;
	}

	
	public TimeSeriesSchema(String[] schema) {
		this.schema = Arrays.copyOf(schema, schema.length);
		this.constantTimeStep = false;
		this.timeStep = NO_CONSTANT_TIMESTEP;
		this.columns = schema.length;
		this.isContinuous = false;
		this.hasQualityFlags = false;
		this.hasInterpolatedFlags = false;
		this.hasQualityCounters = false;
		if(!checkConsistency()) {
			throw new RuntimeException("schema not consistent");
		}
	}
	
	public TimeSeriesSchema(String[] schema, int timeStep) {
		this.schema = Arrays.copyOf(schema, schema.length);
		this.constantTimeStep = true;
		this.timeStep = timeStep;
		this.columns = schema.length;
		this.isContinuous = false;
		this.hasQualityFlags = false;
		this.hasInterpolatedFlags = false;
		this.hasQualityCounters = false;
		if(!checkConsistency()) {
			throw new RuntimeException("schema not consistent");
		}
	}
	
	public TimeSeriesSchema(String[] schema, int timeStep, boolean isContinuous) {
		this.schema = Arrays.copyOf(schema, schema.length);
		this.constantTimeStep = true;
		this.timeStep = timeStep;
		this.columns = schema.length;
		this.isContinuous = isContinuous;
		this.hasQualityFlags = false;
		this.hasInterpolatedFlags = false;
		this.hasQualityCounters = false;
		if(!checkConsistency()) {
			throw new RuntimeException("schema not consistent");
		}
	}
	
	public TimeSeriesSchema(String[] schema, boolean constantTimeStep, int timeStep, boolean isContinuous, boolean hasQualityFlags, boolean hasInterpolatedFlags, boolean hasQualityCounters) {
		this.schema = Arrays.copyOf(schema, schema.length);
		this.constantTimeStep = constantTimeStep;
		this.timeStep = timeStep;
		this.columns = schema.length;
		this.isContinuous = isContinuous;
		this.hasQualityFlags = hasQualityFlags;
		this.hasInterpolatedFlags = hasInterpolatedFlags;
		this.hasQualityCounters = hasQualityCounters;
		if(!checkConsistency()) {
			throw new RuntimeException("schema not consistent");
		}
	}
	
	@Override
	public String toString() {
		String s="schema: ["+schema.length;
		for(int i=0;i<schema.length;i++) {
			s+= " "+schema[i];
		}
		s+="] ";
		if(constantTimeStep) {
			s+=" [time step: "+timeStep+"] ";
		}
		if(isContinuous) {
			s+=" [continuous] ";
		}
		if(hasQualityFlags) {
			s+=" [quality flags] ";
		}
		if(hasInterpolatedFlags) {
			s+=" [interpolation flags] ";
		}
		if(hasQualityCounters) {
			s+=" [quality counters]   ";
		}
		return s;
	}
	
	

}
