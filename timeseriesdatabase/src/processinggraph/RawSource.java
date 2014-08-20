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
	public final Station station; // not null
	public final String[] schema; //not null

	protected RawSource(TimeSeriesDatabase timeSeriesDatabase, Station station, String[] schema) {
		super(timeSeriesDatabase);	
		this.station = station;
		this.schema = schema;
		if(this.station==null) {
			throw new RuntimeException("no station");
		}
		if(this.schema==null || this.schema.length==0) {
			throw new RuntimeException("no schema");
		}
		if(!station.isValidSchema(schema)) {
			throw new RuntimeException("not valid schema: "+Util.arrayToString(schema)+" in "+Util.arrayToString(station.loggerType.sensorNames)); 
		}
	}

	public static RawSource create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema) {
		Station station = timeSeriesDatabase.getStation(stationName);
		if(station==null) {
			throw new RuntimeException("station not found: "+stationName);
		}
		return create(timeSeriesDatabase, station, querySchema);
	}
	
	public static RawSource create(TimeSeriesDatabase timeSeriesDatabase, Station station, String[] querySchema) {
		if(querySchema==null) {
			querySchema = station.loggerType.sensorNames;
		}
		if(!station.isValidSchema(querySchema)) {
			throw new RuntimeException("not valid schema: "+Util.arrayToString(querySchema)+" in "+Util.arrayToString(station.loggerType.sensorNames)); 
		}
		return new RawSource(timeSeriesDatabase, station, querySchema);
	}
	
	public static Node create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema, DataQuality dataQuality) {
		RawSource node = create(timeSeriesDatabase, stationName, querySchema);
		if(DataQuality.Na==dataQuality) {
			return node;
		} else {
			return QualityFilter.create(timeSeriesDatabase, node, dataQuality);
		}
	}
	
	public static Node create(TimeSeriesDatabase timeSeriesDatabase, Station station, String[] querySchema, DataQuality dataQuality) {
		RawSource node = create(timeSeriesDatabase, station, querySchema);
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

	@Override
	public String[] getSchema() {
		return schema;
	}

	
}
