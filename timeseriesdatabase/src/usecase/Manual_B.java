package usecase;

import java.util.ArrayList;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.iterator.ManualFillIterator;
import timeseriesdatabase.aggregated.iterator.NanGapIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Builder;
import util.iterator.InputProcessingIterator;
import util.iterator.TimeSeriesIterator;

public class Manual_B {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");

		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();

		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		String plotID = "fer0";
		String[] querySchema = new String[]{"B_01"};
		Long queryStart = null;
		Long queryEnd = null;
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		//AggregationInterval aggregationInterval = AggregationInterval.HOUR;
		boolean interpolated = true;
		//TimeSeriesIterator it = new Builder(()->qp.virtualquery_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, interpolated),null,null).create();

		TimeSeriesIterator it = qp.query_base_aggregated("8", null, null, null, DataQuality.NO);
		
		//it.writeCSV(CSV_OUTPUT_PATH+"Manual_B_org.csv");

		TimeSeriesIterator result_iterator = new ManualFillIterator(it);
		result_iterator = new NanGapIterator(result_iterator, null, null);
		
		result_iterator.writeCSV(CSV_OUTPUT_PATH+"Manual_B.csv");



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
