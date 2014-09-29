package tsdb;

import static tsdb.util.AssumptionCheck.throwNull;
import tsdb.util.TsDBLogger;

public abstract class TsDBClient implements TsDBLogger {
	
	protected final TsDB tsdb; //not null
	
	public TsDBClient(TsDB tsdb) {
		throwNull(tsdb);
		this.tsdb = tsdb;
	}

}
