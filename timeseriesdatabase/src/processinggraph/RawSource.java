package processinggraph;

import java.util.Iterator;

import de.umr.jepc.store.Event;
import timeseriesdatabase.DataQuality;
import timeseriesdatabase.LoggerType;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.iterator.EventConverterIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class RawSource extends Node {
	public final Station station;
	public final String[] schema;

	protected RawSource(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema) {
		super(timeSeriesDatabase);
		this.station = timeSeriesDatabase.getStation(stationName);
		if(this.station==null) {
			throw new RuntimeException("station not found: "+stationName);
		}
		if(querySchema==null) {
			this.schema = station.loggerType.sensorNames;
		} else {
			this.schema = station.getValidSchemaEntries(querySchema);
			if(this.schema.length!=querySchema.length) {
				throw new RuntimeException("not valid schema: "+Util.arrayToString(querySchema)+" in "+Util.arrayToString(station.loggerType.sensorNames)); 
			}
		}
		if(this.schema.length==0) {
			throw new RuntimeException("no schema");
		}
	}

	public static RawSource create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema) {
		return new RawSource(timeSeriesDatabase, stationName, querySchema);
	}
	
	public static Node create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, DataQuality dataQuality) {
		RawSource node = create(timeSeriesDatabase, stationName, querySchema);
		if(DataQuality.Na==dataQuality) {
			return node;
		} else {
			return QualityFilter.create(timeSeriesDatabase, node, dataQuality);
		}
	}
	

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		Iterator<Event> rawEventIterator = timeSeriesDatabase.streamStorage.queryRawEvents(station.stationID, start, end);
		if(rawEventIterator==null||!rawEventIterator.hasNext()) {
			return null;
		}
		EventConverterIterator raw_iterator = new EventConverterIterator(station.loggerType.sensorNames, rawEventIterator, schema);
		if(!raw_iterator.hasNext()) {
			return null;
		}
		return raw_iterator;
	}

	@Override
	public Station getSourceStation() {
		return this.station;
	}

	@Override
	public boolean isContinuous() {
		return false;
	}
}
