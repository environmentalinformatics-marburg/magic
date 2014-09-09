package tsdb.usecase;

import java.util.List;

import tsdb.FactoryTsDB;
import tsdb.QueryProcessor;
import tsdb.StationProperties;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.util.TimestampInterval;

public class VirtualPlotQueryProcessing {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = FactoryTsDB.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		String plotName = "cof3";
		Long queryStart = null;
		Long queryEnd = null;
		String[] schema = null;
		
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotName);
		List<TimestampInterval<StationProperties>> intervalList = virtualPlot.getStationList(queryStart, queryEnd, schema);
		for(TimestampInterval<StationProperties> interval:intervalList) {
			System.out.println(interval.value.get_plotid()+" "+interval.value.get_logger_type_name()+"\t\t"+TimeConverter.oleMinutesToText(interval.start)+"\t-\t"+TimeConverter.oleMinutesToText(interval.end));
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
