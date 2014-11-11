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

	/*private static class ChunkSerializerSimple implements Serializer<DataEntry[]>, Serializable {
		private static final long serialVersionUID = -5944450269165056735L;
		@Override
		public void serialize(DataOutput out, DataEntry[] value)
				throws IOException {
			out.writeInt(value.length);
			for(DataEntry entry:value) {
				out.writeInt(entry.timestamp);
				out.writeFloat(entry.value);
			}
		}
		@Override
		public DataEntry[] deserialize(DataInput in, int available) throws IOException {
			int count = in.readInt();
			DataEntry[] a = new DataEntry[count];
			for(int i=0;i<a.length;i++) {
				int t = in.readInt();
				float v = in.readFloat();
				a[i] = new DataEntry(t,v);
			}
			return a;
		}
		@Override
		public int fixedSize() {
			return -1;
		}		
	};

	public static final Serializer<DataEntry[]> CHUNK_SERIALIZER_SIMPLE = new ChunkSerializerSimple();

	private static class ChunkSerializerDeltaTime implements Serializer<DataEntry[]>, Serializable {
		private static final long serialVersionUID = -5944450269165056735L;
		@Override
		public void serialize(DataOutput out, DataEntry[] value) throws IOException {
			out.writeInt(value.length);
			int prev = 0;
			for(DataEntry entry:value) {
				out.writeInt(entry.timestamp-prev);
				prev = entry.timestamp;
			}
			for(DataEntry entry:value) {
				out.writeFloat(entry.value);
			}
		}
		@Override
		public DataEntry[] deserialize(DataInput in, int available) throws IOException {
			int count = in.readInt();
			int[] timestamps = new int[count];
			int curr = 0;
			for(int i=0;i<timestamps.length;i++) {
				curr += in.readInt();
				timestamps[i] = curr;
			}
			DataEntry[] a = new DataEntry[count];
			for(int i=0;i<count;i++) {
				float v = in.readFloat();
				a[i] = new DataEntry(timestamps[i],v);
			}
			return a;
		}
		@Override
		public int fixedSize() {
			return -1;
		}		
	};
	
	public static final Serializer<DataEntry[]> CHUNK_SERIALIZER_DELTA_TIME = new ChunkSerializerDeltaTime();
	
	private static class ChunkSerializerDeltaTimeDeltaIntValue implements Serializer<DataEntry[]>, Serializable {
		private static final long serialVersionUID = -5944450269165056735L;
		@Override
		public void serialize(DataOutput out, DataEntry[] value)
				throws IOException {
			out.writeInt(value.length);
			int prev = 0;
			for(DataEntry entry:value) {
				out.writeInt(entry.timestamp-prev);
				prev = entry.timestamp;
			}
			int prevValue = 0;
			for(DataEntry entry:value) {
				if(Float.isNaN(entry.value)) {
					throw new RuntimeException("NaN Value in stream");
				}
				int curr = (int) (entry.value*1000f);
				out.writeInt(curr-prevValue);
				prevValue = curr;
			}
		}
		@Override
		public DataEntry[] deserialize(DataInput in, int available) throws IOException {
			int count = in.readInt();
			int[] timestamps = new int[count];
			int curr = 0;
			for(int i=0;i<timestamps.length;i++) {
				curr += in.readInt();
				timestamps[i] = curr;
			}
			DataEntry[] a = new DataEntry[count];
			int currValue = 0; 
			for(int i=0;i<a.length;i++) {
				currValue += in.readInt();
				a[i] = new DataEntry(timestamps[i],currValue/1000f); // no mul for better rounding!!!
			}
			return a;
		}
		@Override
		public int fixedSize() {
			return -1;
		}		
	};
	
	public static final Serializer<DataEntry[]> CHUNK_SERIALIZER_DELTA_TIME_DELTA_INT_VALUE = new ChunkSerializerDeltaTimeDeltaIntValue();*/
}