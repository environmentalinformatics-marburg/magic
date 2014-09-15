package tsdb.graph;

import java.util.Arrays;

import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.iterator.ProjectionIterator;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class CacheBase extends Base.Abstract {

	private final String streamName; //not null
	private final String[] schema; //not null

	private CacheBase(TsDB tsdb, String streamName, String[] schema) {
		super(tsdb);
		Util.throwNull(streamName,schema);
		this.streamName = streamName;
		this.schema = schema;
	}

	public static CacheBase create(TsDB tsdb, String streamName, String[] schema) {
		TsSchema tsSchema = tsdb.cacheStorage.getSchema(streamName);
		if(schema==null) {
			schema = tsSchema.names;
		}		
		if(schema.length==0 || !tsSchema.contains(schema)) {
			throw new RuntimeException("not valid schema: "+ Arrays.toString(schema) +"   "+tsSchema);
		}
		return new CacheBase(tsdb, streamName, schema);
	}

	@Override
	public TsIterator get(Long start, Long end) {
		TsIterator it = tsdb.cacheStorage.query(streamName, start, end);
		if(it==null || !it.hasNext()) {
			return null;
		}
		TsIterator proj = new ProjectionIterator(it,schema);
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
