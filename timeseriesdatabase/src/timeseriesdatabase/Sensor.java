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
	
	public AggregationType baseAggregationType;
	
	public Sensor(String name) {
		this.name = name;
		min = -Float.MAX_VALUE;
		max = Float.MAX_VALUE;
		baseAggregationType = AggregationType.NONE;
	}
	
	public boolean checkPhysicalRange(float value) {
		if(Float.isNaN(value)) {
			return false;
		}
		return min<=value&&value<=max;
		
	}

}
