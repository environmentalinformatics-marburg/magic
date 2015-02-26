package tsdb.graph;

import java.util.Iterator;

import static tsdb.util.AssumptionCheck.throwNulls;
import tsdb.DataRow;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.raw.iterator.EventConverterIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

/**
 * This node is the source of station values.
 * @author woellauer
 *
 */
public class StationRawSource extends RawSource.Abstract {
	public final Station station; // not null
	public final String[] schema; //not null, schema valid

	protected StationRawSource(TsDB tsdb, Station station, String[] schema) {
		super(tsdb);
		throwNulls(station,schema);
		this.station = station;
		this.schema = schema;
		if(this.schema.length==0) {
			throw new RuntimeException("no schema");
		}
		if(!station.isValidSchema(schema)) {
			throw new RuntimeException("not valid schema: "+Util.arrayToString(schema)+" in "+Util.arrayToString(station.loggerType.sensorNames)); 
		}
	}

	public static StationRawSource of(TsDB tsdb, String stationName, String[] querySchema) {
		Station station = tsdb.getStation(stationName);
		if(station==null) {
			throw new RuntimeException("station not found: "+stationName);
		}
		return of(tsdb, station, querySchema);
	}
	
	public static StationRawSource of(TsDB tsdb, Station station, String[] querySchema) {
		if(querySchema==null) {
			querySchema = station.loggerType.sensorNames;
		}
		return new StationRawSource(tsdb, station, querySchema);
	}
	

	@Override
	public TsIterator get(Long start, Long end) {
		return tsdb.streamStorage.getRawIterator(station.stationID, schema, start, end, station.loggerType.sensorNames);
		/*Iterator<Event> rawEventIterator = tsdb.streamStorage.queryRawEvents(station.stationID, start, end);
		if(rawEventIterator==null||!rawEventIterator.hasNext()) {
			return null;
		}
		EventConverterIterator raw_iterator = new EventConverterIterator(station.loggerType.sensorNames, rawEventIterator, schema);
		if(!raw_iterator.hasNext()) {
			return null;
		}
		return raw_iterator;*/
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
