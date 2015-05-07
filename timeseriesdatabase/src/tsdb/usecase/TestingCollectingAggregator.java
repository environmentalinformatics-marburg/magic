package tsdb.usecase;

import java.util.ArrayList;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.graph.Node;
import tsdb.graph.QueryPlan;
import tsdb.iterator.DayCollectingAggregator;
import tsdb.iterator.MonthCollectingAggregator;
import tsdb.util.DataQuality;
import tsdb.util.TimeConverter;
import tsdb.util.iterator.TsIterator;

public class TestingCollectingAggregator {
	private static final Logger log = LogManager.getLogger();

	public static void main(String[] args) {
		TsDB tsdb = TsDBFactory.createDefault();

		Node node = QueryPlan.getStationGen(tsdb, DataQuality.STEP).get("HEG01", new String[]{"Ta_200"});
		//node.writeConsole(null, null);

		TsIterator it = node.get(null, null);

		DayCollectingAggregator mca = new DayCollectingAggregator(it);
		//MonthCollectingAggregator mca = new MonthCollectingAggregator(new DayCollectingAggregator(it));


		mca.calcNextOutput();

		while(mca.outputTimestamp>=0) {
			//if(mca.outputs[0].size()<24) {
				System.out.println(TimeConverter.oleMinutesToText(mca.outputTimestamp)+"  "+mca.outputs[0].size());
				ArrayList<Float> values = mca.outputs[0];
				float s = 0;
				float c = 0;
				float min = Float.MAX_VALUE;
				float max = -Float.MAX_VALUE;
				for(Float v:values) {
					s += v;
					c++;
					min = Float.min(min,v);
					max = Float.max(max, v);
				}
				System.out.println(min+"  "+s/c+"  "+max);
				values.sort(null);
				System.out.println(values.get(0)+"  "+values.get(values.size()/4)+"  "+values.get(values.size()/2)+"  "+values.get(values.size()*3/4)+"  "+values.get(values.size()-1));
			//}
			mca.calcNextOutput();
		}

	}
}