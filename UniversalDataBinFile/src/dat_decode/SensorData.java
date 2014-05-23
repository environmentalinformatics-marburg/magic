package dat_decode;

/**
 * Collection of all sensor of one location.
 * @author Wöllauer
 *
 */
public class SensorData {
	
	private TimeConverter timeConverter;
	private Sensor[] sensors;
	
	public SensorData(TimeConverter timeConverter, SensorHeader[] sensorHeaders, double[][] data) {
		this.timeConverter = timeConverter;
		sensors = new Sensor[sensorHeaders.length];
		for(int i=0;i<sensors.length;i++) {
			double[] col = new double[data.length];
			for(int r=0;r<data.length;r++) {
				col[r] = data[r][i];
			}
			sensors[i] = new Sensor(timeConverter, sensorHeaders[i],col);
		}
	}
	
	public Sensor getSensor(int sensorID) {
		return sensors[sensorID];		
	}
	
	

}
