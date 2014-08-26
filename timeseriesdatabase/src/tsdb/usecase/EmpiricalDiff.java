package tsdb.usecase;

import java.util.Iterator;
import java.util.List;
import java.util.stream.Stream;

import javax.management.RuntimeErrorException;

import tsdb.DataQuality;
import tsdb.FactoryTsDB;
import tsdb.QueryProcessor;
import tsdb.Station;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.CSV;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

/**
 * Testing quality checks for empirical quality checks.
 * @author woellauer
 *
 */
public class EmpiricalDiff {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";
	private static final int NEAR_STATIONS = 3;//10;

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = FactoryTsDB.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);


		String basePlotID = "HEW08";
		String sensorName = "Ts_5";
		//String sensorName = "Ta_200";
		//String sensorName = "Ts_50";
		//String sensorName = "Albedo";
		//String sensorName = "Ts_20";
		String[] querySchema = new String[]{sensorName};
		Long queryStart = 56936340l;
		Long queryEnd = 59809800l;
		DataQuality dataQuality = DataQuality.PHYSICAL;
		TimeSeriesIterator itBase = qp.query_continuous_base_aggregated(basePlotID, querySchema, queryStart, queryEnd, dataQuality);



		List<Station> nearList = timeSeriesDatabase.getStation(basePlotID).getNearestStationsWithSensor(sensorName);
		
		Stream<Station> stream = nearList.stream();
		Stream<TimeSeriesIterator> stream1 = stream.map(x->qp.query_continuous_base_aggregated(x.stationID, querySchema, queryStart, queryEnd, dataQuality));
		Iterator<TimeSeriesIterator> it = stream1.iterator();

		TimeSeriesIterator[] itNear = new TimeSeriesIterator[NEAR_STATIONS];
		int c = Util.fillArray(nearList, itNear, x->qp.query_continuous_base_aggregated(x.stationID, querySchema, queryStart, queryEnd, dataQuality));
		if(c<NEAR_STATIONS) {
			throw new RuntimeException("c: "+c+" "+nearList.size());
		}

		/*
		CSV.write(itBase, CSV_OUTPUT_PATH+"EmpiricalDiff_base.csv");

		for(int i=0;i<NEAR_STATIONS;i++) {
			CSV.write(itNear[i], CSV_OUTPUT_PATH+"EmpiricalDiff_"+i+".csv");
		}
		 */

		TimeSeriesIterator itDiff = new TimeSeriesIterator(new TimeSeriesSchema(new String[]{"value","min_diff","avg_diff","valid_min","valid_avg","step"})) {
			private float prevValue = Float.NaN;
			
			@Override
			public boolean hasNext() {
				return itBase.hasNext();
			}
			@Override
			public TimeSeriesEntry next() {
				TimeSeriesEntry base = itBase.next();
				if(!Float.isNaN(base.data[0])) {
					float avgCnt = 0;
					float avgSum = 0;
					float minDiff = Float.MAX_VALUE;
					for(int i=0;i<NEAR_STATIONS;i++) {
						TimeSeriesEntry near = itNear[i].next();
						if(!Float.isNaN(near.data[0])) {
							if(base.timestamp!=near.timestamp) {
								System.out.println(base.timestamp+" "+near.timestamp);
								throw new RuntimeException();
							}
							float diff = Math.abs(near.data[0]-base.data[0]);
							if(diff<minDiff) {
								minDiff = diff;
							}
							avgCnt++;
							avgSum+=diff;
						}
					}
					if(minDiff==Float.MAX_VALUE) {
						minDiff = Float.NaN;
					}
					float valid_min_Value = base.data[0];
					float valid_avg_Value = base.data[0];
					if(minDiff>0.7) {
						valid_min_Value = Float.NaN; 
					}
					if(avgSum/avgCnt>1.5) {
						valid_avg_Value = Float.NaN; 
					}
					float stepValue;
					if(!Float.isNaN(prevValue)) {
						stepValue = base.data[0]-prevValue;
					} else {
						stepValue = Float.NaN;
					}
					prevValue = base.data[0];
					return new TimeSeriesEntry(base.timestamp, new float[]{base.data[0],minDiff,avgSum/avgCnt,valid_min_Value,valid_avg_Value,stepValue});
				} else {
					for(int i=0;i<NEAR_STATIONS;i++) {
						itNear[i].next();						
					}
					prevValue = Float.NaN;
					return new TimeSeriesEntry(base.timestamp, new float[]{base.data[0],Float.NaN,Float.NaN,Float.NaN});
				}
			}
			@Override
			public List<ProcessingChainEntry> getProcessingChain() {
				return null;
			}
			@Override
			public String getIteratorName() {
				return "diff";
			}			
		};


		CSV.write(itDiff, CSV_OUTPUT_PATH+"EmpiricalDiff_base.csv");

		System.out.println("...end");
	}

}
