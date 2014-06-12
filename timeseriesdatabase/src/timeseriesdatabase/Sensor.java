package timeseriesdatabase;

public class Sensor {
	
	public String name;
	public float min;
	public float max;
	
	public Sensor(String name) {
		this.name = name;
		min = -Float.MAX_VALUE;
		max = Float.MAX_VALUE;
	}

}
