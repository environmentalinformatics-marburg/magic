package timeseriesdatabase.raw;

import java.sql.Time;

/**
 * entry in TimestampSeries
 * @author woellauer
 *
 */
public class TimestampSeriesEntry {
	public long timestamp;
	public float[] data;
	public TimestampSeriesEntry(long timestamp,float[] data) {
		this.timestamp = timestamp;
		this.data = data;
	}
}