package tsdb;

import org.apache.logging.log4j.Logger;

import tsdb.util.TsDBLogger;
import tsdb.util.Util;

public abstract class TsDBClient implements TsDBLogger {
	
	protected final TsDB tsdb; //not null
	
	public TsDBClient(TsDB tsdb) {
		Util.throwNull(tsdb);
		this.tsdb = tsdb;
	}

}
