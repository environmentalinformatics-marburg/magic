package dat_decode;

public class SensorHeader {
	
	public final String name;
	public final String unit;
	public short dataType;

	public SensorHeader(String name, String unit, short dataType) {
		this.name = name;
		this.unit = unit;
		this.dataType = dataType;
	}

	public void printHeader() {
		System.out.println("sensor: "+name+"\t unit: "+unit);
		
	}

}
