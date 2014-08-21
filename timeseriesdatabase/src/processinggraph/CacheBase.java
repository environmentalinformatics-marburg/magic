package processinggraph;

import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.iterator.ProjectionIterator;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class CacheBase extends Base.Abstract {

	private final String streamName; //not null
	private final String[] schema; //not null

	private CacheBase(TimeSeriesDatabase timeSeriesDatabase, String streamName, String[] schema) {
		super(timeSeriesDatabase);
		Util.throwNull(streamName,schema);
		this.streamName = streamName;
		this.schema = schema;
	}

	public static CacheBase create(TimeSeriesDatabase timeSeriesDatabase, String streamName, String[] schema) {
		TimeSeriesSchema tsSchema = timeSeriesDatabase.cacheStorage.getSchema(streamName);
		if(schema==null) {
			schema = tsSchema.schema;
		}		
		if(schema.length==0 || !Util.isContained(schema, tsSchema.schema)) {
			throw new RuntimeException("not valid schema: "+Util.arrayToString(schema)+"   "+Util.arrayToString(tsSchema.schema));
		}
		return new CacheBase(timeSeriesDatabase, streamName, schema);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		TimeSeriesIterator it = timeSeriesDatabase.cacheStorage.query(streamName, start, end);
		if(it==null || !it.hasNext()) {
			return null;
		}
		TimeSeriesIterator proj = new ProjectionIterator(it,schema);
		if(proj==null || !proj.hasNext()) {
			return null;
		}
		return proj;
	}

	@Override
	public Station getSourceStation() {
		return null;
	}

	@Override
	public boolean isContinuous() {
		return false; //TODO
	}

	@Override
	public String[] getSchema() {
		return schema;
	}
}
