package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNulls;

import java.util.ArrayList;
import java.util.List;

import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.streamdb.StreamChainIterator;
import tsdb.streamdb.StreamIterator;
import tsdb.streamdb.StreamTsIterator;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class VirtualRawSource extends RawSource.Abstract {

	private final VirtualPlot virtualPlot;
	private final String[] schema;

	private VirtualRawSource(TsDB tsdb, VirtualPlot virtualPlot, String[] schema) {
		super(tsdb);
		throwNulls(virtualPlot, schema);

		this.virtualPlot = virtualPlot;
		this.schema = schema;
		if(this.schema.length==0) {
			throw new RuntimeException("no schema");
		}
		if(this.schema.length!=1) {
			throw new RuntimeException("only one senor allowed");
		}
		if(!virtualPlot.isValidSchema(schema)) {
			throw new RuntimeException("not valid schema: "+Util.arrayToString(schema)+" in "+Util.arrayToString(virtualPlot.getSchema())); 
		}
	}

	public static VirtualRawSource of(TsDB tsdb, VirtualPlot virtualPlot, String[] querySchema) {
		if(querySchema==null) {
			querySchema = virtualPlot.getSchema();
		}
		return new VirtualRawSource(tsdb, virtualPlot, querySchema);
	}


	@Override
	public TsIterator get(Long start, Long end) {		
		List<TimestampInterval<StationProperties>> intervalList = virtualPlot.getStationList(start, end, schema);			 
		List<StreamIterator> processing_iteratorList = new ArrayList<StreamIterator>();				
		for(TimestampInterval<StationProperties> interval:intervalList) {
			String[] stationSchema = tsdb.getValidSchema(interval.value.get_serial(), schema);
			if(stationSchema.length>0) {

				StreamIterator it = tsdb.streamStorage.getRawSensorIterator(interval.value.get_serial(), schema[0], interval.start, interval.end); // just one sensor
				if(it!=null&&it.hasNext()) {
					processing_iteratorList.add(it);
				}
			}
		}
		if(processing_iteratorList.isEmpty()) {
			return null;
		}

		StreamChainIterator it = new StreamChainIterator(processing_iteratorList);

		if(!it.hasNext()) {
			return null;
		}	

		return new StreamTsIterator(it, schema[0]); // just one sensor
	}

	@Override
	public Station getSourceStation() {
		return null;
	}

	@Override
	public boolean isContinuous() {
		return false;
	}

	@Override
	public boolean isConstantTimestep() {
		return false;
	}

	@Override
	public String[] getSchema() {
		return schema;
	}

}
