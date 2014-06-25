package timeseriesdatabase.aggregated;

/**
 * aggregation type of sensor data
 * @author Stephan Wöllauer
 *
 */
public enum AggregationType {	
	NONE,	// no aggregation
	AVERAGE,
	SUM,
	AVERAGE_WIND_DIRECTION, // special aggregation for wind direction
	AVERAGE_WIND_VELOCITY,  // helper tag for calculation of AVERAGE_WIND_DIRECTION 
	MAXIMUM,
	AVERAGE_ZERO //average aggregation type, NaN values are interpreted as 0
}