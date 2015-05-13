package tsdb.usecase;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.graph.Node;
import tsdb.graph.QueryPlan;
import tsdb.util.AggregationInterval;
import tsdb.util.DataQuality;
import tsdb.util.TsEntry;
import tsdb.util.iterator.TsIterator;

public class TestingQualityCounters {

	public static void main(String[] args) {
		TsDB tsdb = TsDBFactory.createDefault();
		String plotID = "HEG01";
		String[] columnNames = new String[]{"Ta_200","rH_200"};
		AggregationInterval aggregationInterval = AggregationInterval.MONTH;
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		boolean interpolated = true;
		Node node = QueryPlan.plot(tsdb, plotID, columnNames, aggregationInterval, dataQuality, interpolated);		
		TsIterator it = node.get(null, null);
		while(it.hasNext()) {
			TsEntry e = it.next();
			System.out.println(e);
		}
		
		System.out.println(it.getSchema());

	}

}
