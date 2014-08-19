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
import util.iterator.TimeSeriesIterator;

public class VirtualBase extends Base  {

	private final VirtualPlot virtualPlot;	
	private final String[] schema;
	private final DataQuality dataQuality;

	public VirtualBase(TimeSeriesDatabase timeSeriesDatabase, VirtualPlot virtualPlot, String[] schema, DataQuality dataQuality) {
		super(timeSeriesDatabase);
		this.virtualPlot = virtualPlot;
		this.schema = schema;
		this.dataQuality = dataQuality;
	}

	public static VirtualBase create(TimeSeriesDatabase timeSeriesDatabase, String plotID, String[] querySchema) {
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotID);
		if(virtualPlot==null) {
			throw new RuntimeException();
		}
		if(querySchema==null) {
			querySchema = timeSeriesDatabase.getBaseAggregationSchema(virtualPlot.getSchema());
		}
		return new VirtualBase(timeSeriesDatabase, virtualPlot, querySchema, DataQuality.Na);
	}
	
	public static VirtualBase create(TimeSeriesDatabase timeSeriesDatabase, String plotID, String[] querySchema, DataQuality dataQuality) {
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotID);
		if(virtualPlot==null) {
			throw new RuntimeException();
		}
		if(querySchema==null) {
			querySchema = timeSeriesDatabase.getBaseAggregationSchema(virtualPlot.getSchema());
		}
		return new VirtualBase(timeSeriesDatabase, virtualPlot, querySchema, dataQuality);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {		
		List<TimestampInterval<StationProperties>> intervalList = virtualPlot.getStationList(start, end, schema);			 
		List<TimeSeriesIterator> processing_iteratorList = new ArrayList<TimeSeriesIterator>();				
		for(TimestampInterval<StationProperties> interval:intervalList) {
			String[] stationSchema = timeSeriesDatabase.getValidSchema(interval.value.get_serial(), schema);
			if(stationSchema.length>0) {
				Node node = StationBase.create(timeSeriesDatabase, interval.value.get_serial(), stationSchema, dataQuality);
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
}
