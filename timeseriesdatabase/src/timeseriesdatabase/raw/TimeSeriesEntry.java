package timeseriesdatabase.raw;

import java.sql.Time;

public class TimeSeriesEntry {
	public long timestamp;
	public float[] data;
	public TimeSeriesEntry(long timestamp,float[] data) {
		this.timestamp = timestamp;
		this.data = data;
	}
}