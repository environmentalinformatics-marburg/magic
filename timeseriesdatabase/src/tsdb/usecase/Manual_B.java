package tsdb.usecase;

import java.time.LocalDateTime;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.QueryProcessor;
import tsdb.Station;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.aggregated.iterator.NanGapIterator;
import tsdb.aggregated.iterator.PeakSmoothIterator;
import tsdb.graph.Base;
import tsdb.graph.Continuous;
import tsdb.graph.Node;
import tsdb.graph.NodeGen;
import tsdb.graph.PeakSmoothed;
import tsdb.graph.QueryPlan;
import tsdb.graph.RangeStepFiltered;
import tsdb.graph.StationRawSource;
import tsdb.graph.VirtualBase;
import tsdb.util.iterator.TsIterator;

public class Manual_B {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");

		TsDB tsdb = TsDBFactory.createDefault();

		QueryProcessor qp = new QueryProcessor(tsdb);

		//String plotID = "sav5";
		String plotID = "fer0";
		String[] querySchema = new String[]{"B_03"};
		//Long queryStart = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2012,11,7,9,20,00));
		//Long queryEnd = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2014,8,6,12,22,00));
		
		Long queryStart = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2012,11,01,03,20,00));
		Long queryEnd = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2014,8,8,8,25,00));
		
		
		DataQuality dataQuality = DataQuality.NO;
		//AggregationInterval aggregationInterval = AggregationInterval.HOUR;
		boolean interpolated = false;
		//TimeSeriesIterator it = new Builder(()->qp.virtualquery_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, interpolated),null,null).create();

		//TimeSeriesIterator it = qp.query_base_aggregated("8", null, null, null, DataQuality.NO);
		
		//it.writeCSV(CSV_OUTPUT_PATH+"Manual_B_org.csv");

		//TimeSeriesIterator result_iterator = new PeakSmoothIterator(it);
		//result_iterator = new NanGapIterator(result_iterator, null, null);
		
		AggregationInterval aggregationInterval = AggregationInterval.HOUR;
		Node node = QueryPlan.plot(tsdb, plotID, querySchema, aggregationInterval , dataQuality, interpolated);
		
		node.get(queryStart, queryEnd).writeCSV(CSV_OUTPUT_PATH+"Manual_B.csv");
		
		
		NodeGen stationGen = (String stationID, String[] schema)->{
			Station station = tsdb.getStation(stationID);
			if(station==null) {
				throw new RuntimeException("station not found");
			}
			Node rawSource = StationRawSource.of(tsdb, stationID, schema);
			if(DataQuality.Na==dataQuality) {
				return rawSource;
			} else {
				return RangeStepFiltered.of(tsdb, rawSource, dataQuality);
			}
		};
		
		
		
		Continuous.of(Base.of(tsdb, plotID, querySchema, stationGen)).get(queryStart, queryEnd).writeCSV(CSV_OUTPUT_PATH+"Manual_B_raw.csv");
		
		
		//result_iterator.writeCSV(CSV_OUTPUT_PATH+"Manual_B.csv");



		/*while(result_iterator.hasNext()) {
			TimeSeriesEntry e = result_iterator.next();
			//if(!Float.isNaN(e.data[0])) {
				System.out.println(e);
			//}
		}*/

		/*TimeSeriesIterator itnew = qp.query_base_aggregated("8", null, null, null, DataQuality.EMPIRICAL);
		System.out.println("vor: "+itnew);
		itnew = new NanGapIterator(itnew,null,null);
		System.out.println("nach: "+itnew);

		while(itnew.hasNext()) {
			TimeSeriesEntry e = itnew.next();
			System.out.println(e);
		}*/


		System.out.println("...end");

	}

}
