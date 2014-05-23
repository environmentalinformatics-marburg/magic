package dat_decode;

/**
 * Data entries of one sensor with title, unit and time.
 * @author Wöllauer
 *
 */
public class Sensor {
	
	TimeConverter timeConverter;
	SensorHeader metaData;
	double[] data;
	
	public Sensor(TimeConverter timeConverter, SensorHeader metaData,double[] data) {
		this.timeConverter = timeConverter;
		this.metaData = metaData;
		this.data = data;
	}
	
	public void print(int n) {
		System.out.print("sensor: "+metaData.getName()+"\tunit: "+metaData.getUnit()+" ("+data.length+" entries) @"+timeConverter.getStartDateTime()+" :  ");
		if(data.length<n) {
			n = data.length;
		}
		for(int i=0;i<n;i++) {
			System.out.print(data[i]+"\t");
		}
		System.out.println();
	}

}
