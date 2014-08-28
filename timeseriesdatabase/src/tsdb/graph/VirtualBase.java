package tsdb.graph;

import java.util.ArrayList;
import java.util.List;

import tsdb.DataQuality;
import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.aggregated.iterator.VirtualPlotIterator;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class VirtualBase extends Base.Abstract  {

	private final VirtualPlot virtualPlot; //not null	
	private final String[] schema; // not null
	private final NodeGen stationGen; // not null

	protected VirtualBase(TsDB tsdb, VirtualPlot virtualPlot, String[] schema, NodeGen stationGen) {
		super(tsdb);
		Util.throwNull(virtualPlot, schema, stationGen);
		if(schema.length==0) {
			throw new RuntimeException("no schema");
		}
		if(!Util.isContained(schema, tsdb.getBaseSchema(virtualPlot.getSchema()))) {
			throw new RuntimeException("schema not valid  "+schema+"  in  "+tsdb.getBaseSchema(virtualPlot.getSchema()));
		}
		this.virtualPlot = virtualPlot;
		this.schema = schema;
		this.stationGen = stationGen;
	}
	
	public static VirtualBase create(TsDB tsdb, VirtualPlot virtualPlot, String[] querySchema, NodeGen stationGen) {
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
	public TimeSeriesIterator get(Long start, Long end) {		
		List<TimestampInterval<StationProperties>> intervalList = virtualPlot.getStationList(start, end, schema);			 
		List<TimeSeriesIterator> processing_iteratorList = new ArrayList<TimeSeriesIterator>();				
		for(TimestampInterval<StationProperties> interval:intervalList) {
			String[] stationSchema = tsdb.getValidSchema(interval.value.get_serial(), schema);
			if(stationSchema.length>0) {
				//Node node = StationBase.create(timeSeriesDatabase, interval.value.get_serial(), stationSchema, dataQuality);
				Station station = tsdb.getStation(interval.value.get_serial());
				Node node = StationBase.create(tsdb, station, stationSchema, stationGen);
				TimeSeriesIterator it = node.get(interval.start, interval.end);
				if(it!=null&&it.hasNext()) {
					processing_iteratorList.add(it);
				}
			}
		}
		if(processing_iteratorList.isEmpty()) {
			return null;
		}
		VirtualPlotIterator virtual_iterator = new VirtualPlotIterator(schema, processing_iteratorList.toArray(new TimeSeriesIterator[0]),virtualPlot.plotID);			
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
