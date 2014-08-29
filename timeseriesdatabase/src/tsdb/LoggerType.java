package tsdb;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

import de.umr.jepc.Attribute;

/**
 * This class contains metadata that associated with a logger type (station type).
 * @author woellauer
 *
 */
public class LoggerType implements Serializable {
	
	private static final long serialVersionUID = -8623721500856325122L;
	public String typeName;
	public Attribute[] schema;
	public String[] sensorNames;
	public Map<String,String> sensorNameTranlationMap;
	
	public LoggerType(String typeName, String[] sensorNames, Attribute[] schema) {
		this.typeName = typeName;
		this.sensorNames = sensorNames;
		this.schema = schema;
		this.sensorNameTranlationMap = new HashMap<String, String>();
	}
	
	@Override
	public String toString() {
		return "logger: "+typeName;
	}

}
