package usecase;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.iterator.InputProcessingIterator;
import util.iterator.TimeSeriesIterator;

public class Manual_B {

	public static void main(String[] args) {
		System.out.println("start...");
		
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String plotID = "fer0";
		String[] querySchema = new String[]{"B_01"};
		Long queryStart = null;
		Long queryEnd = null;
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		AggregationInterval aggregationInterval = AggregationInterval.HOUR;
		boolean interpolated = true;
		TimeSeriesIterator it = qp.virtualquery_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
		
		
		InputProcessingIterator result_iterator = new InputProcessingIterator(it, it.getOutputTimeSeriesSchema()) {			
			@Override
			protected TimeSeriesEntry getNext() {
				if(!this.input_iterator.hasNext()) {
					return null;
				}
				TimeSeriesEntry curr = input_iterator.next();
				TimeSeriesEntry result=null;
				
				//TimeSeriesEntry prev = curr;
				return result;
			}			
		};
		
		
		
		while(it.hasNext()) {
			TimeSeriesEntry e = it.next();
			if(!Float.isNaN(e.data[0])) {
				System.out.println(e);
			}
		}
		
		
		System.out.println("...end");

	}

}
