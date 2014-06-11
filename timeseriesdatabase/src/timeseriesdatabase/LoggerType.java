package timeseriesdatabase;

import java.util.HashMap;
import java.util.Map;

import de.umr.jepc.Attribute;

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
