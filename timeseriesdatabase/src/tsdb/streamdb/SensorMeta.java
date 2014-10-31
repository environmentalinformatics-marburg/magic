package tsdb.streamdb;
import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;

import org.mapdb.Serializer;

public class SensorMeta {
	
	private static final String DB_NAME_SENSOR_CHUNK_MAP_PREFIX = "sensorChunkMap/";
	
	public static class ChunkMetaEntry {
		public int firstTimestamp;
		public int lastTimestamp;
		public ChunkMetaEntry(int firstTimestamp, int lastTimestamp) {
			this.firstTimestamp = firstTimestamp;
			this.lastTimestamp = lastTimestamp;
		}
	}
	
	public final String db_name_sensor_chunk_map;
	
	public final String stationName;
	public final String name;

	public ArrayList<ChunkMetaEntry> list;
	
	public SensorMeta(String stationName, String name) {
		this.stationName = stationName;
		this.name = name;
		this.db_name_sensor_chunk_map = DB_NAME_SENSOR_CHUNK_MAP_PREFIX+stationName+"/"+name;
		this.list = new ArrayList<ChunkMetaEntry>(); 
	}
	
	private SensorMeta(String stationName, String name, String db_name_sensor_chunk_map, ArrayList<ChunkMetaEntry> list) {
		this.stationName = stationName;
		this.name = name;
		this.db_name_sensor_chunk_map = db_name_sensor_chunk_map;
		this.list = list;
	}
	
	private static class SensorMetaSerializer implements Serializer<SensorMeta>, Serializable {
		private static final long serialVersionUID = -4064482638307132258L;
		@Override
		public void serialize(DataOutput out, SensorMeta value)
				throws IOException {
			out.writeUTF(value.stationName);
			out.writeUTF(value.name);
			out.writeUTF(value.db_name_sensor_chunk_map);
			out.writeInt(value.list.size());
			for(ChunkMetaEntry entry:value.list) {
				out.writeInt(entry.firstTimestamp);
				out.writeInt(entry.lastTimestamp);
			}
		}
		@Override
		public SensorMeta deserialize(DataInput in, int available) throws IOException {			
			String sn = in.readUTF();
			String n = in.readUTF();
			String d = in.readUTF();
			int count = in.readInt();
			ArrayList<ChunkMetaEntry> a = new ArrayList<ChunkMetaEntry>(count);
			for(int i=0;i<count;i++) {
				int f = in.readInt();
				int l = in.readInt(); 
				a.add(new ChunkMetaEntry(f,l));
			}
			return new SensorMeta(sn,n,d,a);
		}
		@Override
		public int fixedSize() {
			return -1;
		}		
	};
	
	public static final Serializer<SensorMeta> SERIALIZER = new SensorMetaSerializer();

}
