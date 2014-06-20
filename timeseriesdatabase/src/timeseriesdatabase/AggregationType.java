package timeseriesdatabase;

/**
 * aggregation type of sensor data
 * @author Stephan Wöllauer
 *
 */
enum AggregationType {	
	NONE,	// no aggregation
	AVERAGE,
	SUM,
	AVERAGE_WIND_DIRECTION, // special aggregation for wind direction
	AVERAGE_WIND_VELOCITY,  // helper tag for calculation of AVERAGE_WIND_DIRECTION 
	MAXIMUM
}