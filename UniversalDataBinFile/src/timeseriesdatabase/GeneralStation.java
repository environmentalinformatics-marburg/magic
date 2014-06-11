package timeseriesdatabase;

import java.util.Map;

public class GeneralStation {
	
	private String generalName;
	private Map<String, String> sensorNameMap;
	
	public GeneralStation(String generalName, Map<String, String> sensorNameMap) {
		this.generalName = generalName;
		this.sensorNameMap = sensorNameMap;
	}
	
	public String getNormalizedName(String rawSensorName) {
		return sensorNameMap.get(rawSensorName);
	}

}
