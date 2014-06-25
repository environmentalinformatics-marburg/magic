package timeseriesdatabase;

import timeseriesdatabase.aggregated.AggregationType;

/**
 * This class contains metadata that is associated with a sensor.
 * Only sensors that are part of base aggregation are created.
 * @author Stephan Wöllauer
 *
 */
public class Sensor {
	
	/**
	 * parameter name of this sensor
	 */
	public String name;
	
	/**
	 * physical minimum
	 */
	public float min;
	
	/**
	 * physical maximum
	 */
	public float max;
	
	/**
	 * Type of aggregation for base aggregation
	 */
	public AggregationType baseAggregationType;
	
	/**
	 * fill gaps in time series of this sensor
	 */
	public boolean useGapFilling;
	
	public Sensor(String name) {
		this.name = name;
		min = -Float.MAX_VALUE;
		max = Float.MAX_VALUE;
		baseAggregationType = AggregationType.NONE;
		useGapFilling = false;
	}
	
	/**
	 * checks if value is in physical range
	 * @param value  value == NaN  ==> false
	 * @return if false value should not be included in further processing
	 */
	public boolean checkPhysicalRange(float value) {
		if(Float.isNaN(value)) {
			return false;
		}
		return min<=value&&value<=max;		
	}
}
