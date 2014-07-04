package timeseriesdatabase.raw;

import java.sql.Time;

import org.omg.CORBA.DATA_CONVERSION;

import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.raw.iterator.QualityFlagIterator.DataQualtity;
import util.Util;

/**
 * entry in TimestampSeries
 * @author woellauer
 *
 */
public class TimeSeriesEntry {
	
	public final long timestamp;	
	public final float[] data;
	public final DataQualtity[] qualityFlag;
	
	public TimeSeriesEntry(long timestamp,float[] data) {
		this.timestamp = timestamp;
		this.data = data;
		this.qualityFlag = null;
	}
	
	public TimeSeriesEntry(long timestamp, float[] data, DataQualtity[] qualityFlag) {
		this.timestamp = timestamp;
		this.data = data;
		this.qualityFlag = qualityFlag;
	}
	
	public static TimeSeriesEntry getNaN(long timestamp, int columnCount) {
		return new TimeSeriesEntry(timestamp, getNanData(columnCount));
	}
	
	public static float[] getNanData(int columnCount) {
		float[] data = new float[columnCount];
		for(int i=0;i<columnCount;i++) {
			data[i] = Float.NaN;
		}
		return data;
	}
	
	@Override
	public String toString() {
		return " < "+timestamp+": "+TimeConverter.oleMinutesToLocalDateTime(timestamp)+" > "+Util.arrayToString(data);
	}
}