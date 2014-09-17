package tsdb;

import java.util.HashMap;
import java.util.Map;

import tsdb.util.Util;

/**
 * This class contains data that is common for station and virtual plot
 * @author woellauer
 *
 */
public class Plot {
	
	public final String name;

	//Map SensorName -> correction value
	public Map<String,Float> correctionValueMap;
	
	public Plot(String name) {
		Util.throwNull(name);
		this.name = name;
		correctionValueMap = new HashMap<String, Float>();
	}

}
