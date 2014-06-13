package timeseriesdatabase;

import java.util.HashMap;
import java.util.Map;

import de.umr.jepc.Attribute;

/**
 * This class contains metadata that associated with a logger type (station type).
 * @author Stephan Wöllauer
 *
 */
public class LoggerType {
	
	public String typeName;
	public Attribute[] schema;
	public Map<String,String> sensorNameTranlationMap;
	
	public LoggerType(String typeName, Attribute[] schema) {
		this.typeName = typeName;
		this.schema = schema;
		this.sensorNameTranlationMap = new HashMap<String, String>();
	}

}
