package tsdb.test;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.TsDB;
import tsdb.graph.Base;
import tsdb.graph.NodeGen;
import tsdb.graph.QueryPlan;

public class BaseTest {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TsDB tsdb = TsDBFactory.createDefault();
		
		NodeGen stationGen = QueryPlan.getStationGen(tsdb, DataQuality.EMPIRICAL);
		Base.of(tsdb, "HEG01", null, stationGen).writeConsole(null, null);
		Base.of(tsdb, "cof1", null, stationGen).writeConsole(null, null);
		
		System.out.println(".end");
	}

}
