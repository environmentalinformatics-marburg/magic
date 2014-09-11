package tsdb.aggregated;

import tsdb.util.TsDBLogger;
import tsdb.util.TsSchema;
import tsdb.util.TsSchema.Aggregation;

public enum AggregationInterval implements TsDBLogger {
	HOUR, 
	DAY, 
	WEEK, 
	MONTH, 
	YEAR;
	
	public String getText() {
		switch(this) {
		case HOUR:
			return "hour";
		case DAY:
			return "day";
		case WEEK:
			return "week";
		case MONTH:
			return "month";
		case YEAR:
			return "year";
		default:
			log.warn("aggregation unknown");
			return "unknown";
		}		
	}
	
	public Aggregation toAggregation() {
		switch(this) {
		case HOUR:
			return Aggregation.CONSTANT_STEP;
		case DAY:
			return Aggregation.CONSTANT_STEP;
		case WEEK:
			return Aggregation.CONSTANT_STEP;
		case MONTH:
			return Aggregation.MONTH;
		case YEAR:
			return Aggregation.YEAR;
		default:
			log.warn("aggregation unknown");
			return Aggregation.NO;
		}			
	}
	
	public int toTimeStep() {
		switch(this) {
		case HOUR:
			return 60;
		case DAY:
			return 24*60;
		case WEEK:
			return 7*24*60;
		case MONTH:
			return TsSchema.NO_CONSTANT_TIMESTEP;
		case YEAR:
			return TsSchema.NO_CONSTANT_TIMESTEP;
		default:
			log.warn("aggregation unknown");
			return TsSchema.NO_CONSTANT_TIMESTEP;
		}			
	}


}