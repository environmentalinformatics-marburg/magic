package tsdb.streamdb;
import tsdb.TimeConverter;

public class DataEntry {
	public final int timestamp;
	public final float value;

	public DataEntry(int timestamp, float value) {
		this.timestamp = timestamp;
		this.value = value;
	}
	
	@Override
	public String toString() {
		return timestamp+" "+TimeConverter.oleMinutesToText((long) timestamp)+" "+value;
	}
}