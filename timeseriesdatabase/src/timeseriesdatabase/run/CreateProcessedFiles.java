package timeseriesdatabase.run;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.aggregated.AggregationInterval;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class CreateProcessedFiles {
	
	protected static final Logger log = Util.log;
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();

		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		
		for(VirtualPlot virtualPlot:timeSeriesDatabase.getVirtualPlots()) {
			if(virtualPlot.generalStation!=null&&virtualPlot.generalStation.region!=null&&virtualPlot.generalStation.region.name.equals("KI")) {
				try {
				String plotID = virtualPlot.plotID;
				String[] querySchema = null; //new String[]{"Ta_200"};
				Long queryStart = null;
				Long queryEnd = null;
				DataQuality dataQuality = DataQuality.EMPIRICAL;
				AggregationInterval aggregationInterval = AggregationInterval.MONTH;
				boolean interpolated = true;
				TimeSeriesIterator it = qp.virtualquery_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
				if(it!=null&&it.hasNext()) {
					System.out.println("process: "+virtualPlot.plotID);
					it.writeCSV(CSV_OUTPUT_PATH+"processed/"+plotID+".csv");
				}
				} catch (Exception e) {
					e.printStackTrace();
					log.warn("error in "+virtualPlot.plotID+"   "+e);
				}
			}
		}






		System.out.println("...end");
	}

}
