package tsdb.aggregated;

import tsdb.util.TsDBLogger;

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
			log.warn("data quality unknown");
			return "unknown";
		}		
	}


}