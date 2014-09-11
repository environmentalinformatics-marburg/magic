package tsdb.usecase;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import de.umr.jepc.util.Timer;
import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.QueryProcessor;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;

public class ParallelQuery {

	private static class Worker implements Runnable {

		private QueryProcessor qp;
		private String plotID;

		public Worker(QueryProcessor qp, String plotID) {
			this.qp = qp;
			this.plotID = plotID;
		}

		@Override
		public void run() {
			String[] querySchema = null;
			Long queryStart = null;
			Long queryEnd = null;
			DataQuality dataQuality = DataQuality.EMPIRICAL;
			AggregationInterval aggregationInterval = AggregationInterval.YEAR;
			boolean interpolated = true;		

			qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
		}

	}

	public static void main(String[] args) throws InterruptedException {
		System.out.println("start...");
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		//final int THREAD_COUNT = 2;

		/*
		 * 	par_query0: 28509 ms
			par_query1: 21585 ms
			par_query2: 21718 ms
			seq_query0: 33274 ms
			seq_query1: 33897 ms
			seq_query2: 33290 ms
		 */
		
		
		ExecutorService executor = Executors.newFixedThreadPool(5);
		Timer timer = new Timer();

		timer.start("query");
		for(int i=0;i<2;i++) {
			executor.execute(new Worker(qp, "HEG01"));
			executor.execute(new Worker(qp, "HEG02"));
			executor.execute(new Worker(qp, "HEG03"));
			executor.execute(new Worker(qp, "HEG04"));
		}
		executor.shutdown();		
		executor.awaitTermination(1, TimeUnit.DAYS);
		timer.stop("query");
		
		timer.printTime("query");
		
		//query: 43321 ms   5
		
		//query: 39418 ms   4
		
		//query: 44823 ms   2
		
		//query: 74539 ms   1

		System.out.println("...end");
	}

}
