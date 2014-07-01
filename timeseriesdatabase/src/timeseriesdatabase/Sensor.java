package timeseriesdatabase;

import timeseriesdatabase.aggregated.AggregationType;

/**
 * This class contains metadata that is associated with a sensor.
 * Only sensors that are part of base aggregation are created.
 * @author woellauer
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
	public float physicalMin;
	
	/**
	 * physical maximum
	 */
	public float physicalMax;
	
	/**
	 * empirical minimum
	 */
	public float empiricalMin;
	
	/**
	 * empirical maximum
	 */
	public float empiricalMax;
	
	/**
	 * minimal change within a base aggregation time interval
	 */
	public float stepMin;
	
	/**
	 * maximum change within a base aggregation time interval
	 */
	public float stepMax;
	
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
		physicalMin = -Float.MAX_VALUE;
		physicalMax = Float.MAX_VALUE;
		empiricalMin = -Float.MAX_VALUE;
		empiricalMax = Float.MAX_VALUE;
		stepMin = 0.0f;
		stepMax = Float.MAX_VALUE;
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
		return physicalMin<=value&&value<=physicalMax;		
	}

	public boolean checkEmpiricalRange(float value) {
		if(Float.isNaN(value)) {
			return false;
		}
		return empiricalMin<=value&&value<=empiricalMax;
	}

	/**
	 * precondition: prevValue and value are valid (no NaN values)
	 * @param prevValue
	 * @param value
	 * @return
	 */
	public boolean checkStepRange(float prevValue, float value) {
		float step = Math.abs(value-prevValue);		
		return stepMin<=step&&step<=stepMax;
	}
}
