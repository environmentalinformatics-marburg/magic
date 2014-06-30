package timeseriesdatabase.raw;

import java.sql.Time;

import org.omg.CORBA.DATA_CONVERSION;

import timeseriesdatabase.TimeConverter;
import util.Util;

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
	
	public static TimestampSeriesEntry getNaN(long timestamp, int columnCount) {
		float[] data = new float[columnCount];
		for(int i=0;i<columnCount;i++) {
			data[i] = Float.NaN;
		}
		return new TimestampSeriesEntry(timestamp, data);
	}
	
	@Override
	public String toString() {
		return " < "+timestamp+": "+TimeConverter.oleMinutesToLocalDateTime(timestamp)+" > "+Util.arrayToString(data);
	}
}