package structure;

import java.util.HashMap;
import java.util.Map;

public class Station {
	
	public final String stationID;
	private String plotID = "";
	private String serialNumber = "";
	private Map<String, Sensor> sensorMap = new HashMap<String, Sensor>();
	
	public Station(String stationID) {
		this.stationID = stationID;
	}


}
