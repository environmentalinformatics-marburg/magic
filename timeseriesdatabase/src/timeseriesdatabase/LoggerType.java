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
	public Attribute[] _schema;
	public String[] sensorNames;
	public Map<String,String> sensorNameTranlationMap;
	
	public LoggerType(String typeName, String[] sensorNames, Attribute[] schema) {
		this.typeName = typeName;
		this.sensorNames = sensorNames;
		this._schema = schema;
		this.sensorNameTranlationMap = new HashMap<String, String>();
	}

}
