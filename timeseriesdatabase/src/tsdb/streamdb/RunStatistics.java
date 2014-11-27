package tsdb.streamdb;

import tsdb.TsDBFactory;

public class RunStatistics {

	public static void main(String[] args) {
		StreamDB streamDB = new StreamDB(TsDBFactory.STORAGE_PATH+"/"+"streamdb");
		streamDB.printStatistics();
		streamDB.close();

	}

}
