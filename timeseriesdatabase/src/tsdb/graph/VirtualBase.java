package tsdb.graph;

import java.util.ArrayList;
import static tsdb.util.AssumptionCheck.throwNulls;
import java.util.Arrays;
import java.util.List;

import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.aggregated.iterator.VirtualPlotIterator;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

/**
 * This node creates base aggregated data of one virtual plot that consist of multiple station sources
 * @author woellauer
 *
 */
public class VirtualBase extends Base.Abstract  {

	private final VirtualPlot virtualPlot; //not null	
	private final String[] schema; // not null
	private final NodeGen stationGen; // not null

	protected VirtualBase(TsDB tsdb, VirtualPlot virtualPlot, String[] schema, NodeGen stationGen) {
		super(tsdb);
		throwNulls(virtualPlot, schema, stationGen);
		if(schema.length==0) {
			throw new RuntimeException("no schema");
		}
		if(!Util.isContained(schema, tsdb.getBaseSchema(virtualPlot.getSchema()))) {
			throw new RuntimeException("schema not valid  "+Arrays.toString(schema)+"  in  "+Arrays.toString(tsdb.getBaseSchema(virtualPlot.getSchema())));
		}
		this.virtualPlot = virtualPlot;
		this.schema = schema;
		this.stationGen = stationGen;
	}
	
	public static VirtualBase of(TsDB tsdb, VirtualPlot virtualPlot, String[] querySchema, NodeGen stationGen) {
		if(querySchema==null) {
			String[] schema = virtualPlot.getSchema();
			if(schema==null) {
				throw new RuntimeException("empty VirtualPlot: "+virtualPlot.plotID);
			}			
			querySchema = tsdb.getBaseSchema(schema);
			if(querySchema==null) {
				throw new RuntimeException("empty base schema in VirtualPlot: "+virtualPlot.plotID);
			}
		}
		return new VirtualBase(tsdb, virtualPlot, querySchema, stationGen);		
	}

	@Override
	public TsIterator get(Long start, Long end) {		
		List<TimestampInterval<StationProperties>> intervalList = virtualPlot.getStationList(start, end, schema);			 
		List<TsIterator> processing_iteratorList = new ArrayList<TsIterator>();				
		for(TimestampInterval<StationProperties> interval:intervalList) {
			String[] stationSchema = tsdb.getValidSchema(interval.value.get_serial(), schema);
			if(stationSchema.length>0) {
				//Node node = StationBase.create(timeSeriesDatabase, interval.value.get_serial(), stationSchema, dataQuality);
				Station station = tsdb.getStation(interval.value.get_serial());
				Node node = StationBase.of(tsdb, station, stationSchema, stationGen);
				TsIterator it = node.get(interval.start, interval.end);
				if(it!=null&&it.hasNext()) {
					processing_iteratorList.add(it);
				}
			}
		}
		if(processing_iteratorList.isEmpty()) {
			return null;
		}
		VirtualPlotIterator virtual_iterator = new VirtualPlotIterator(schema, processing_iteratorList.toArray(new TsIterator[0]),virtualPlot.plotID);			
		if(virtual_iterator==null||!virtual_iterator.hasNext()) {
			return null;
		}
		return virtual_iterator;
	}
	
	@Override
	public boolean isContinuous() {
		return false; // maybe todo
	}

	@Override
	public Station getSourceStation() {
		return null; // source unknown
	}

	@Override
	public String[] getSchema() {
		return schema;
	}
}
