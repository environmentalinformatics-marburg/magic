package tsdb.usecase;

import java.util.ArrayList;
import java.util.List;

import tsdb.DataQuality;
import tsdb.FactoryTsDB;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.graph.NodeGen;
import tsdb.graph.QueryPlan;
import tsdb.graph.StationBase;
import tsdb.util.iterator.TimeSeriesIterator;
import tsdb.util.iterator.TimeSeriesIteratorIterator;

public class AverageDiff {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB tsdb = FactoryTsDB.createDefault();
		NodeGen stationGen = QueryPlan.getStationGen(tsdb, DataQuality.STEP);

		for(String name:tsdb.getBaseAggregationSensorNames()) {
			System.out.println("process: "+name);
			String[] schema = new String[]{name};
			List<TimeSeriesIterator> iterator_list = new ArrayList<TimeSeriesIterator>();
			for(Station station:tsdb.getStations()) {
				if(station.isValidBaseSchema(schema)) {
					StationBase node = StationBase.create(tsdb, station, schema, stationGen);
					TimeSeriesIterator it = node.get(null, null);
					if(it!=null&&it.hasNext()) {
						iterator_list.add(it);
					}
				}
			}
			if(!iterator_list.isEmpty()) {
				TimeSeriesIteratorIterator result_iterator = new TimeSeriesIteratorIterator(iterator_list,schema);
				result_iterator.writeCSV(CSV_OUTPUT_PATH+"AverageDiff/"+name+".csv");
			}
		}


		System.out.println("...end");
	}

}
