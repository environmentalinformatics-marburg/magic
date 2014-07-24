package usecase;

import java.util.concurrent.ConcurrentNavigableMap;
import java.util.function.Function;

import de.umr.jepc.util.Timer;
import timeseriesdatabase.DataQuality;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.iterator.EmpiricalIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Builder;
import util.CSV;
import util.iterator.TimeSeriesIterator;

/**
 * Testing empirical diff check.
 * @author woellauer
 *
 */
public class UseCaseAverageGeneralStationQuery {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";
	
	private static Function<TimeSeriesEntry, TimeSeriesEntry> createDiffFunc(TimeSeriesIterator compareIt) {
		return new Function<TimeSeriesEntry, TimeSeriesEntry>() {			
			@Override
			public TimeSeriesEntry apply(TimeSeriesEntry element) {
				TimeSeriesEntry genElement = compareIt.next();
				long timestamp = element.timestamp;
				if(timestamp!= genElement.timestamp) {
					throw new RuntimeException("iterator error");
				}
				float[] result = new float[element.data.length];

				for(int colIndex=0;colIndex<element.data.length;colIndex++) {
					result[colIndex] = Float.NaN;
					if(!Float.isNaN(genElement.data[colIndex])) {
						if(!Float.isNaN(element.data[colIndex])) {
							result[colIndex] = element.data[colIndex]-genElement.data[colIndex];
						} 
					} 
				}				
				return new TimeSeriesEntry(timestamp,result);
			}
		};		
	}
	
	/*private static Function<TimeSeriesEntry, TimeSeriesEntry> createCheckFunc(TimeSeriesIterator compareIt) {
		return new Function<TimeSeriesEntry, TimeSeriesEntry>() {			
			@Override
			public TimeSeriesEntry apply(TimeSeriesEntry element) {
				TimeSeriesEntry genElement = compareIt.next();
				long timestamp = element.timestamp;
				if(timestamp!= genElement.timestamp) {
					throw new RuntimeException("iterator error");
				}
				float[] result = new float[element.data.length];

				for(int colIndex=0;colIndex<element.data.length;colIndex++) {
					if(!Float.isNaN(genElement.data[colIndex])) {
						if(!Float.isNaN(element.data[colIndex])) {
							float diff = Math.abs(element.data[colIndex]-genElement.data[colIndex]);
							//final float MAX_DIFF = 1.519f;
							final float MAX_DIFF = 4f;
							if(diff<=MAX_DIFF) { // passed empirical check
								result[colIndex] = element.data[colIndex];
							} else { // passed not empirical check
								result[colIndex] = Float.NaN;
							}
						} else { // value NaN
							result[colIndex] = element.data[colIndex];
						}
					} else { // general value NaN -> empirical check not possible
						result[colIndex] = element.data[colIndex];
					}
				}				
				return new TimeSeriesEntry(timestamp,result);
			}
		};		
	}*/
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		
		for(GeneralStation generalStation:timeSeriesDatabase.generalStationMap.values()) {
			String streamName = generalStation.name;
			Long begin = null;
			Long end = null;
			ConcurrentNavigableMap<Long, TimeSeriesEntry> map = timeSeriesDatabase.cacheStorage.queryMap(streamName, begin, end);
			System.out.println(generalStation.name+": "+TimeConverter.oleMinutesToLocalDateTime(map.firstKey())+"\t-\t"+TimeConverter.oleMinutesToLocalDateTime(map.lastKey()));
			Timer timer = new Timer();
			timer.start(generalStation.name);
			int count = 0;
			for(TimeSeriesEntry value:map.values()) {
				count++;
			}
			timer.stop(generalStation.name);
			System.out.println(count+"\t\t"+timer.toString(generalStation.name));
			
		}
		
		
		//String plotID = "SEW07";
		String plotID = "HEG04";
		String sensorName = "Ts_5";
		String[] querySchema = new String[]{sensorName};
		//Long queryStart = 56936340l;
		//Long queryEnd = 59809800l;
		Long queryStart = timeSeriesDatabase.getFirstTimestampBaseAggregated(plotID);
		Long queryEnd = timeSeriesDatabase.getLastTimestampBaseAggregated(plotID);
		DataQuality dataQuality = DataQuality.STEP;


		
		CSV.write(qp.query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality), CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_org.csv");
		CSV.write(qp.query_empirical_diff_check(plotID, querySchema, queryStart, queryEnd, dataQuality), CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_check.csv");
		String generalName = timeSeriesDatabase.stationMap.get(plotID).generalStationName;
		CSV.write(Builder.project(timeSeriesDatabase.cacheStorage.query(generalName, queryStart, queryEnd),querySchema), CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_general.csv");
		TimeSeriesIterator input_it = qp.query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		TimeSeriesIterator diff_it = Builder.apply(input_it,createDiffFunc(Builder.project(Builder.fill(timeSeriesDatabase.cacheStorage.query(generalName, queryStart, queryEnd), queryStart, queryEnd), input_it)));
		CSV.write(diff_it, CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_diff.csv");
		
		
		System.out.println("...end");
	}

}
