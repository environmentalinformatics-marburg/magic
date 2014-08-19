package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.iterator.BaseAggregationIterator;
import timeseriesdatabase.aggregated.iterator.ManualFillIterator;
import util.iterator.TimeSeriesIterator;

public class StationBase extends Base {

	private final Node source;	
	private final boolean useManualFillIterator;

	protected StationBase(TimeSeriesDatabase timeSeriesDatabase, Node source, boolean useManualFillIterator) {
		super(timeSeriesDatabase);
		this.source = source;
		this.useManualFillIterator = useManualFillIterator;
	}
	
	public static StationBase create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema) {
		return create(timeSeriesDatabase, stationName, querySchema, DataQuality.Na);
	}

	public static StationBase create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, DataQuality dataQuality) {
		Node node = RawSource.create(timeSeriesDatabase,stationName,querySchema, dataQuality);		
		Station station = node.getSourceStation();
		if(station!=null&&station.loggerType.typeName.equals("tfi")) {
			System.out.println("is tfi");
			return new StationBase(timeSeriesDatabase, node, true);
		} else {
			return new StationBase(timeSeriesDatabase, node, false);
		}

	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		BaseAggregationIterator base_iterator = new BaseAggregationIterator(timeSeriesDatabase, input_iterator);
		if(!base_iterator.hasNext()) {
			return null;
		}
		
		if(useManualFillIterator) {
			ManualFillIterator manual_fill_iterator = new ManualFillIterator(base_iterator);
			if(manual_fill_iterator==null||!manual_fill_iterator.hasNext()) {
				return null;
			}
			return manual_fill_iterator;
		} else {
			return base_iterator;
		}		
	}


	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}
	
	@Override
	public boolean isContinuous() {
		return false; // maybe todo
	}
}
