package timeseriesdatabase;

import java.util.List;
import java.util.Map;

/**
 * This class contains metadata that is associated with a group of stations like HEG or HEW.
 * @author Stephan Wöllauer
 *
 */
public class GeneralStation {
	
	public String name;
	
	public Map<String,String> sensorNameTranlationMap;
	
	public List<Station> stationList;
	
	public GeneralStation(String name) {
		this.name = name;
	}

}
