package tsdb.component;

import static tsdb.util.AssumptionCheck.throwNull;

import java.util.HashMap;
import java.util.Map;

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
		throwNull(name);
		this.name = name;
		correctionValueMap = new HashMap<String, Float>();
	}

}
