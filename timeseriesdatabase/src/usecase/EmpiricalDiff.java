package usecase;

import java.util.List;

import javax.management.RuntimeErrorException;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.CSV;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class EmpiricalDiff {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";
	private static final int NEAR_STATIONS = 15;//10;

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);


		String basePlotID = "HEG14";
		//String sensorName = "Ta_200";
		//String sensorName = "Ts_50";
		//String sensorName = "Albedo";
		String sensorName = "Ts_20";
		String[] querySchema = new String[]{sensorName};
		Long queryStart = 56936340l;
		Long queryEnd = 59809800l;
		DataQuality dataQuality = DataQuality.STEP;
		TimeSeriesIterator itBase = qp.query_continuous_base_aggregated(basePlotID, querySchema, queryStart, queryEnd, dataQuality);



		List<Station> nearList = timeSeriesDatabase.getStation(basePlotID).getNearestStationsWithSensor(sensorName);

		TimeSeriesIterator[] itNear = new TimeSeriesIterator[NEAR_STATIONS];
		int c = Util.fillArray(nearList, itNear, x->qp.query_continuous_base_aggregated(x.plotID, querySchema, queryStart, queryEnd, dataQuality));
		if(c<NEAR_STATIONS) {
			throw new RuntimeException("c: "+c+" "+nearList.size());
		}

		/*
		CSV.write(itBase, CSV_OUTPUT_PATH+"EmpiricalDiff_base.csv");

		for(int i=0;i<NEAR_STATIONS;i++) {
			CSV.write(itNear[i], CSV_OUTPUT_PATH+"EmpiricalDiff_"+i+".csv");
		}
		 */

		TimeSeriesIterator itDiff = new TimeSeriesIterator(new TimeSeriesSchema(new String[]{"value","min_diff","avg_diff","valid_min","valid_avg"})) {
			@Override
			public boolean hasNext() {
				return itBase.hasNext();
			}
			@Override
			public TimeSeriesEntry next() {
				/*TimeSeriesEntry base = itBase.next();
				float baseValue = base.data[0];
				long baseTimestamp = base.timestamp;
				//System.out.println("baseTimestamp:"+baseTimestamp);
				float minDiff = Float.MAX_VALUE;
				if(!Float.isNaN(baseValue)) {
					for(int i=0;i<NEAR_STATIONS;i++) {
						if(!itNear[i].hasNext()) {
							throw new RuntimeException("no elements left");
						}
						TimeSeriesEntry entry = itNear[i].next();
						if(baseTimestamp!=entry.timestamp) {
							throw new RuntimeException("wrong timestamp: "+baseTimestamp+" "+entry.timestamp+" "+TimeConverter.oleMinutesToLocalDateTime(baseTimestamp)+" "+TimeConverter.oleMinutesToLocalDateTime(entry.timestamp));
						}
						float value = entry.data[0];
						if(!Float.isNaN(value)) {
							float diff = Math.abs(value - baseValue);
							if(diff<minDiff) {
								minDiff = diff;
							}
						}
					}
				}
				if(minDiff == Float.MAX_VALUE) {
					minDiff = Float.NaN;
				}
				System.out.println("baseTimestamp:"+baseTimestamp+" baseValue: "+baseValue+" minDiff: "+minDiff);				
				return new TimeSeriesEntry(baseTimestamp, new float[]{baseValue,minDiff});*/
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
					if(minDiff>2) {
						valid_min_Value = Float.NaN; 
					}
					if(avgSum/avgCnt>2) {
						valid_avg_Value = Float.NaN; 
					}
					return new TimeSeriesEntry(base.timestamp, new float[]{base.data[0],minDiff,avgSum/avgCnt,valid_min_Value,valid_avg_Value});
				} else {
					for(int i=0;i<NEAR_STATIONS;i++) {
						itNear[i].next();						
					}
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
