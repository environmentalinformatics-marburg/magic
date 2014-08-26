package tsdb.graph;

import java.util.Iterator;

import de.umr.jepc.store.Event;
import tsdb.DataQuality;
import tsdb.LoggerType;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.raw.iterator.EventConverterIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class RawSource extends Node.Abstract {
	public final Station station; // not null
	public final String[] schema; //not null, schema valid

	protected RawSource(TsDB timeSeriesDatabase, Station station, String[] schema) {
		super(timeSeriesDatabase);
		Util.throwNull(station,schema);
		this.station = station;
		this.schema = schema;
		if(this.schema.length==0) {
			throw new RuntimeException("no schema");
		}
		if(!station.isValidSchema(schema)) {
			throw new RuntimeException("not valid schema: "+Util.arrayToString(schema)+" in "+Util.arrayToString(station.loggerType.sensorNames)); 
		}
	}

	public static RawSource create(TsDB timeSeriesDatabase, String stationName, String[] querySchema) {
		Station station = timeSeriesDatabase.getStation(stationName);
		if(station==null) {
			throw new RuntimeException("station not found: "+stationName);
		}
		return create(timeSeriesDatabase, station, querySchema);
	}
	
	public static RawSource create(TsDB timeSeriesDatabase, Station station, String[] querySchema) {
		if(querySchema==null) {
			querySchema = station.loggerType.sensorNames;
		}
		return new RawSource(timeSeriesDatabase, station, querySchema);
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
	public String[] getSchema() {
		return schema;
	}

	@Override
	public boolean isConstantTimestep() {
		return false;
	}
	
	@Override
	public boolean isContinuous() {
		return false;
	}	
}
