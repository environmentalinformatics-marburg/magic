package timeseriesdatabase.raw;

import java.sql.Time;

/**
 * entry in TimestampSeries
 * @author woellauer
 *
 */
public class TimestampSeriesEntry {
	public final long timestamp;
	public final float[] data;
	public TimestampSeriesEntry(long timestamp,float[] data) {
		this.timestamp = timestamp;
		this.data = data;
	}
}