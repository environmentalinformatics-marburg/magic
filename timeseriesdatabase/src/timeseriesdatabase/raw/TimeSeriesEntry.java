package timeseriesdatabase.raw;

import java.sql.Time;

import org.omg.CORBA.DATA_CONVERSION;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.TimeConverter;
import util.Pair;
import util.Util;

/**
 * entry in TimestampSeries
 * @author woellauer
 *
 */
public class TimeSeriesEntry {

	public final long timestamp;	
	public final float[] data;
	public final DataQuality[] qualityFlag;
	public final int[][] qualityCounter;
	public final boolean[] interpolated;
	
	public TimeSeriesEntry(long timestamp, float[] data, DataQuality[] qualityFlag,int[][] qualityCounter) {
		this(timestamp, data, qualityFlag, qualityCounter, null);
	}
	
	public TimeSeriesEntry(long timestamp, float[] data, DataQuality[] qualityFlag,int[][] qualityCounter,boolean[] interpolated) {
		this.timestamp = timestamp;
		this.data = data;
		this.qualityFlag = qualityFlag;
		this.qualityCounter = qualityCounter;
		this.interpolated = interpolated;
	}

	public TimeSeriesEntry(long timestamp,float[] data) {
		this(timestamp, data, null, null, null);
	}

	public TimeSeriesEntry(long timestamp, float[] data, DataQuality[] qualityFlag) {
		this(timestamp, data, qualityFlag, null, null);
	}
	
	public TimeSeriesEntry(long timestamp, Pair<float[],DataQuality[]> dataPair) {
		this(timestamp,dataPair.a,dataPair.b);
	}
	
	public TimeSeriesEntry(long timestamp, Object unused, Pair<float[],int[][]> dataPair) {		
		this(timestamp,dataPair.a, null,dataPair.b, null);
		if(unused!=null) {
			throw new RuntimeException();
		}
	}

	public static TimeSeriesEntry getNaN(long timestamp, int columnCount) {
		return new TimeSeriesEntry(timestamp, getNanData(columnCount), getNanQuality(columnCount));
	}

	public static float[] getNanData(int columnCount) {
		float[] data = new float[columnCount];
		for(int i=0;i<columnCount;i++) {
			data[i] = Float.NaN;
		}
		return data;
	}
	
	public static DataQuality[] getNanQuality(int columnCount) {
		DataQuality[] qualityFlag = new DataQuality[columnCount];
		for(int i=0;i<columnCount;i++) {
			qualityFlag[i] = DataQuality.Na;
		}
		return qualityFlag;
	}

	@Override
	public String toString() {
		return " < "+timestamp+": "+TimeConverter.oleMinutesToLocalDateTime(timestamp)+" > "+Util.arrayToString(data)+" "+qualityFlagToString();
	}

	public String qualityFlagToString() {
		if(qualityFlag==null) {
			return "[--]";
		} else {
			String s="[";
			for(int qIndex=0; qIndex<qualityFlag.length; qIndex++) {
				switch(qualityFlag[qIndex]) {
				case Na:
					s+='n';
					break;
				case NO:
					s+='0';
					break;
				case PHYSICAL:
					s+='1';
					break;
				case STEP:
					s+='2';
					break;
				case EMPIRICAL:
					s+='3';
					break;
				default:
					s+='?';

				}
			}
			return s+"]";
		}
	}


}