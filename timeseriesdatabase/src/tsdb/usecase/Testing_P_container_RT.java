package tsdb.usecase;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.graph.Node;
import tsdb.graph.RawSource;
import tsdb.raw.TsEntry;
import tsdb.util.TsSchema;
import tsdb.util.iterator.InputIterator;
import tsdb.util.iterator.TsIterator;

public class Testing_P_container_RT {

	public static void main(String[] args) {
		TsDB tsdb = TsDBFactory.createDefault();
		
		
		String stationID = "HEG19";
		String[] schema = new String[]{"P_container_RT"};
		Node rawSource = RawSource.create(tsdb, stationID, schema);
		TsIterator it = rawSource.get(null, null);		
		
		InputIterator calcIt = new InputIterator(it, new TsSchema(new String[]{"P_container_RT","delta_plus","delta_sum","delta_minus"})) {
			
			float prevV = Float.NaN;
			float sumV = 0f;
			
			@Override
			public TsEntry next() {
				TsEntry e = it.next();
				float v = e.data[0];
				float[] data = new float[4];
				data[0] = v;
				if(Float.isNaN(prevV)) {
					data[1] = Float.NaN;
					data[3] = Float.NaN;
				} else {
					if(Float.isNaN(v)) {
						data[1] = Float.NaN;
						data[3] = Float.NaN;
					} else {
						float delta = v-prevV;
						if(delta>=0f&&delta<=50f) {
							data[1] = delta;
						} else {
							data[1] = 0f;
						}
						if(delta<=0f) {
							data[3] = delta;
						} else {
							data[3] = 0f;
						}
					}
				}
				if(!Float.isNaN(data[1])) {
					sumV += data[1];
				}
				data[2] = sumV;
				prevV = v;
				return new TsEntry(e.timestamp, data);
			}			
			@Override
			public boolean hasNext() {
				return it.hasNext();
			}
		};
		
		calcIt.writeCSV(TsDBFactory.get_CSV_output_directory()+"/"+"HEG19_P_container_RT.csv");
		
		System.out.println(TsDBFactory.SOURCE_KI_TFI_PATH);
		
		
		tsdb.close();

	}

}
