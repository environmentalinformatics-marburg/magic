package timeseriesdatabase.aggregated;

/**
 * aggregation type of sensor data
 * @author woellauer
 *
 */
public enum AggregationType {	
	NONE,	// no aggregation
	AVERAGE,
	SUM,
	AVERAGE_WIND_DIRECTION, // special aggregation for wind direction
	AVERAGE_WIND_VELOCITY,  // helper tag for calculation of AVERAGE_WIND_DIRECTION 
	MAXIMUM,
	AVERAGE_ZERO, //average aggregation type, NaN values are interpreted as 0
	AVERAGE_ALBEDO;

	public static AggregationType getAggregationType(String aggregateTypeText) {
		switch(aggregateTypeText.toLowerCase()) {
		case "average":
			return AVERAGE;
		case "sum":
			return SUM;
		case "average_wind_direction":
			return AVERAGE_WIND_DIRECTION;
		case "average_wind_velocity":
			return AVERAGE_WIND_VELOCITY;
		case "maximum":
			return MAXIMUM;
		case "average_zero":
			return AVERAGE_ZERO;
		case "average_albedo":
			return AVERAGE_ALBEDO;
		default:
			return null;
		}
	}
}