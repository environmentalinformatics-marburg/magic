package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNulls;

import java.util.Arrays;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.iterator.ProjectionIterator;
import tsdb.util.TsSchema;
import tsdb.util.iterator.TsIterator;

/**
 * This node provides a source from cache storage.
 * @author woellauer
 *
 */
public class CacheBase extends Base.Abstract {
	
	private static final Logger log = LogManager.getLogger();

	private final String streamName; //not null
	private final String[] schema; //not null

	private CacheBase(TsDB tsdb, String streamName, String[] schema) {
		super(tsdb);
		throwNulls(streamName,schema);
		this.streamName = streamName;
		this.schema = schema;
	}

	public static CacheBase of(TsDB tsdb, String streamName, String[] schema) {
		TsSchema tsSchema = tsdb.cacheStorage.getSchema(streamName);
		if(tsSchema==null) {
			log.warn("no cache stream: "+streamName);
			return null;
		}
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
