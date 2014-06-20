package timeseriesdatabase;

/**
 * This class contains metadata that is associated with a sensor.
 * @author Stephan Wöllauer
 *
 */
public class Sensor {
	
	public String name;
	public float min;
	public float max;
	
	/**
	 * Type of aggregation for base aggregation
	 */
	public AggregationType baseAggregationType;
	
	public Sensor(String name) {
		this.name = name;
		min = -Float.MAX_VALUE;
		max = Float.MAX_VALUE;
		baseAggregationType = AggregationType.NONE;
	}
	
	/**
	 * checks if value is in physical range
	 * @param value
	 * @return if false value should not be included in further processing
	 */
	public boolean checkPhysicalRange(float value) {
		if(Float.isNaN(value)) {
			return false;
		}
		return min<=value&&value<=max;
		
	}

}
