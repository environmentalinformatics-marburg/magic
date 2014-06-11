package timeseriesdatabase;

import java.util.Map;

public class Logger {
	
	private String loggerType;
	private Map<String, String> sensorNameMap;
	
	public Logger(String loggerType, Map<String, String> sensorNameMap) {
		this.loggerType = loggerType;
		this.sensorNameMap = sensorNameMap;
	}
	
	public String getNormalizedName(String rawSensorName) {
		return sensorNameMap.get(rawSensorName);
	}

}
