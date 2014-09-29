package tsdb.run;

import java.io.File;
import java.time.LocalDateTime;

import tsdb.DataQuality;
import tsdb.QueryProcessor;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.VirtualPlot;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import tsdb.util.CSV;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

/**
 * create processed csv files inserted in directory structure of sensor names
 * @author woellauer
 *
 */
public class CreateProcessedFiles implements TsDBLogger {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();

		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		String[] sensorNames = new String[]{
				"Ta_200", 
				"rH_200", 
				"Ts_10",
				"SWDR_300",
				"SWUR_300",
				"LWDR_300",
				"LWUR_300",
				"WD", 
				"WV",
				"p_200",
				"P_container_RT",
				"T_CNR",
				"P_RT_NRT",
				"P_RT_NRT_01",
				"P_RT_NRT_02",
				"F_RT_NRT_01",
				"F_RT_NRT_02",
				"T_RT_NRT_01",
				"T_RT_NRT_02",
				"par_01",
				"par_02",
				"swdr_01",
				"swdr_02",
				"Fog",
				"Rainfall"};
		
		for(String sensorName:sensorNames) {

			String[] querySchema = new String[]{sensorName};

			for(VirtualPlot virtualPlot:timeSeriesDatabase.getVirtualPlots()) {
				if(virtualPlot.generalStation!=null&&virtualPlot.generalStation.region!=null&&virtualPlot.generalStation.region.name.equals("KI")) {
					if(Util.containsString(virtualPlot.getSchema(),sensorName)) {
						try {
							String plotID = virtualPlot.plotID;
							Long queryStart = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2012, 01, 01, 00, 00));
							Long queryEnd = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of  (2012, 12, 31, 23, 59));
							DataQuality dataQuality = DataQuality.EMPIRICAL;
							AggregationInterval aggregationInterval = AggregationInterval.DAY;
							boolean interpolated = true;
							TsIterator it = qp.virtualquery_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
							if(it!=null&&it.hasNext()) {
								System.out.println("process: "+virtualPlot.plotID);
								(new File(CSV_OUTPUT_PATH+"processed/"+sensorName)).mkdir();
								
								long count = 0;
								TimestampSeries timestampSeries = TimestampSeries.create(it);
								for(TimeSeriesEntry e:timestampSeries.entryList) {
									if(!Float.isNaN(e.data[0])) {
										count++;
									}
								}
								if(count>0) {
									CSV.write(timestampSeries,CSV_OUTPUT_PATH+"processed/"+sensorName+"/"+plotID+".csv");
									//it.writeCSV(CSV_OUTPUT_PATH+"processed/"+sensorName+"/"+plotID+".csv");
								}
							}
						} catch (Exception e) {
							e.printStackTrace();
							log.warn("error in "+virtualPlot.plotID+"   "+e);
						}
					}
				}
			}
		}

		System.out.println("...end");
	}
}
