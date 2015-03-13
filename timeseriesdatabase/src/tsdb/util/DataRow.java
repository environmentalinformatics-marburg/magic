package tsdb.util;

public class DataRow {
	
	public final long timestamp;
	public final Float[] data;
	
	public DataRow(Float[] data, long timestamp) {
		this.data = data;
		this.timestamp = timestamp;
	}
}
