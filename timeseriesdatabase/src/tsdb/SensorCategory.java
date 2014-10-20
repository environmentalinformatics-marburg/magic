package tsdb;

import static tsdb.util.Util.log;

public enum SensorCategory {	
	TEMPERATURE,
	WATER,
	OTHER;

	public static SensorCategory parse(String text) {
		switch(text.toLowerCase().trim()) {
		case "temperature":
			return TEMPERATURE;
		case "water":
			return WATER;
		case "other":
			return OTHER;
		default:
			log.warn("SensorCategory unknown: "+text);
			return OTHER;
		}
	}
}
