package tsdb.streamdb;
import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.io.Serializable;

import org.mapdb.Serializer;


public class StationMeta {

	private static final String DB_NAME_SENSOR_MAP_PREFIX = "sensorMap/";
	
	public final String stationName;
	public final String db_name_sensor_map;
	
	public StationMeta(String stationName) {
		this.stationName = stationName;
		this.db_name_sensor_map = DB_NAME_SENSOR_MAP_PREFIX+stationName;
	}
	
	private StationMeta(String name, String db_name_sensor_map) {
		this.stationName = name;
		this.db_name_sensor_map = db_name_sensor_map;
	}
	
	private static class StationMetaSerializer implements Serializer<StationMeta>, Serializable {
		private static final long serialVersionUID = 2948674604488108143L;
		@Override
		public void serialize(DataOutput out, StationMeta value)
				throws IOException {
			out.writeUTF(value.stationName);
			out.writeUTF(value.db_name_sensor_map);
		}
		@Override
		public StationMeta deserialize(DataInput in, int available)
				throws IOException {
			String n = in.readUTF();
			String d = in.readUTF();
			return new StationMeta(n,d);
		}
		@Override
		public int fixedSize() {
			return -1;
		}		
	};
	
	public static final Serializer<StationMeta> SERIALIZER = new StationMetaSerializer();

}
