package tsdb.streamdb;

import tsdb.TsDBFactory;

public class RunStatistics {

	public static void main(String[] args) {
		StreamDB streamDB = new StreamDB(TsDBFactory.STREAMDB_PATH_PREFIX);
		streamDB.printStatistics();
		streamDB.close();

	}

}
