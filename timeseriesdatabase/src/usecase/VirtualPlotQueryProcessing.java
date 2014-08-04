package usecase;

import java.util.ArrayList;
import java.util.List;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.iterator.VirtualPlotIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import timeseriesdatabase.raw.TimestampSeries;
import util.Builder;
import util.TimestampInterval;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class VirtualPlotQueryProcessing {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		String plotName = "cof3";
		Long queryStart = null;
		Long queryEnd = null;
		String[] schema = null;
		
		VirtualPlot virtualPlot = timeSeriesDatabase.virtualplotMap.get(plotName);
		List<TimestampInterval<Station>> intervalList = virtualPlot.getStationList(queryStart, queryEnd, schema);
		for(TimestampInterval<Station> interval:intervalList) {
			System.out.println(interval.value.plotID+" "+interval.value.loggerType+"\t\t"+TimeConverter.oleMinutesToText(interval.start)+"\t-\t"+TimeConverter.oleMinutesToText(interval.end));
		}
		
		
		
		
/*		DataQuality dataQuality = DataQuality.EMPIRICAL;
		boolean interpolated = false;
		qp.virtualquery_aggregated(plotName, schema, queryStart, queryEnd, dataQuality , AggregationInterval.HOUR, interpolated).writeCSV(CSV_OUTPUT_PATH+"virtualPlot.csv");;
*/		
		//Builder.base_aggregated(qp, "51021020164", null, null, null, DataQuality.NO).writeCSV(CSV_OUTPUT_PATH+"kili_51021020164.csv");
		
		
		String serial = "80081025283";
		//Builder.base_aggregated(qp, serial, null, null, null, DataQuality.NO).writeCSV(CSV_OUTPUT_PATH+"kili_"+serial+".csv");
		qp.query_raw(serial, null, null, null).writeCSV(CSV_OUTPUT_PATH+"kili_"+serial+".csv");
		
		
		
		//Builder.(qp, serial, null, null, null, DataQuality.NO).writeCSV(CSV_OUTPUT_PATH+"kili_"+serial+".csv");
		
		





		System.out.println("\n...end");
	}

}
