package dat_decode;


public class TimeSeries {
	
	public final long[] time;
	public final float[][] data;
	public final SensorHeader[] header;
	
	public TimeSeries(SensorHeader[] header, long[] time, float[][] data) {
		this.header = header;
		this.time = time;
		this.data = data;
	}
	
	
}
