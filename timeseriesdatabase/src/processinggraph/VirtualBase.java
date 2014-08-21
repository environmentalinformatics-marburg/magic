package processinggraph;

import java.util.ArrayList;
import java.util.List;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.StationProperties;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.aggregated.iterator.VirtualPlotIterator;
import util.TimestampInterval;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class VirtualBase extends Base.Abstract  {

	private final VirtualPlot virtualPlot; //not null	
	private final String[] schema; // not null
	private final NodeGen stationGen; // not null

	protected VirtualBase(TimeSeriesDatabase timeSeriesDatabase, VirtualPlot virtualPlot, String[] schema, NodeGen stationGen) {
		super(timeSeriesDatabase);
		Util.throwNull(virtualPlot, schema, stationGen);
		if(schema.length==0) {
			throw new RuntimeException("no schema");
		}
		if(!Util.isContained(schema, timeSeriesDatabase.getBaseAggregationSchema(virtualPlot.getSchema()))) {
			throw new RuntimeException("schema not valid  "+schema+"  in  "+timeSeriesDatabase.getBaseAggregationSchema(virtualPlot.getSchema()));
		}
		this.virtualPlot = virtualPlot;
		this.schema = schema;
		this.stationGen = stationGen;
	}
	
	public static VirtualBase create(TimeSeriesDatabase timeSeriesDatabase, VirtualPlot virtualPlot, String[] querySchema, NodeGen stationGen) {
		if(querySchema==null) {
			querySchema = timeSeriesDatabase.getBaseAggregationSchema(virtualPlot.getSchema());
		}
		return new VirtualBase(timeSeriesDatabase, virtualPlot, querySchema, stationGen);		
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {		
		List<TimestampInterval<StationProperties>> intervalList = virtualPlot.getStationList(start, end, schema);			 
		List<TimeSeriesIterator> processing_iteratorList = new ArrayList<TimeSeriesIterator>();				
		for(TimestampInterval<StationProperties> interval:intervalList) {
			String[] stationSchema = timeSeriesDatabase.getValidSchema(interval.value.get_serial(), schema);
			if(stationSchema.length>0) {
				//Node node = StationBase.create(timeSeriesDatabase, interval.value.get_serial(), stationSchema, dataQuality);
				Station station = timeSeriesDatabase.getStation(interval.value.get_serial());
				Node_temp node = StationBase.create(timeSeriesDatabase, station, stationSchema, stationGen);
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
