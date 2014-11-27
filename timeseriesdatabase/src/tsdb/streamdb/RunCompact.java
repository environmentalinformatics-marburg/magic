package tsdb.streamdb;

import tsdb.TsDBFactory;

public class RunCompact {

	public static void main(String[] args) {
		StreamDB streamDB = new StreamDB(TsDBFactory.STORAGE_PATH+"/"+"streamdb");
		streamDB.compact();
		streamDB.close();

	}

}
