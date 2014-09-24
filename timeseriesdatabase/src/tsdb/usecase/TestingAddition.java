package tsdb.usecase;

import tsdb.DataQuality;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.graph.Addition;
import tsdb.graph.Continuous;
import tsdb.graph.QueryPlan;

public class TestingAddition {
	
	public static void main(String[] args) {
		TsDB tsdb = TsDBFactory.createDefault();
		
		String plotID = "foc1";
		
		Continuous source = QueryPlan.getContinuousGen(tsdb, DataQuality.STEP).get(plotID, new String[]{"Ta_200"});
		source = Addition.createWithElevationTemperature(tsdb, source, plotID);
		source.writeConsole(null, null);
	}

}
