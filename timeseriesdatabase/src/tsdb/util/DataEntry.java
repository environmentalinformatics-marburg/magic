package tsdb.util;
import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

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

	private static class TimeSeriesArchivDataEntryArraySerializer implements org.mapdb.Serializer<DataEntry[]> {

		private final static String TOC_START = "DataEntryArray:start";
		private final static String TOC_END = "DataEntryArray:end";

		@Override
		public void serialize(DataOutput out, DataEntry[] dataEntries) throws IOException {
			out.writeUTF(TOC_START);
			
			out.writeInt(dataEntries.length);
			
			int prevTimestamp = -1;
			for(DataEntry entry:dataEntries) {
				if(entry.timestamp<=prevTimestamp) {
					throw new RuntimeException("write timestampseries format error: timestamps not ascending ordered");
				}
				out.writeInt(entry.timestamp);
				out.writeFloat(entry.value);
				prevTimestamp = entry.timestamp;
			}	

			out.writeUTF(TOC_END);
		}

		@Override
		public DataEntry[] deserialize(DataInput in, int available) throws IOException {
			return null;
		}

		@Override
		public int fixedSize() {
			return -1;
		}
	}
	
	public static final org.mapdb.Serializer<DataEntry[]> TIMESERIESARCHIV_SERIALIZER = new TimeSeriesArchivDataEntryArraySerializer();
}