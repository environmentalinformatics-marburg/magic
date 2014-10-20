package tsdb.usecase;

import java.util.concurrent.ConcurrentNavigableMap;
import java.util.function.Function;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.GeneralStation;
import tsdb.QueryProcessor;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.raw.TsEntry;
import tsdb.util.Builder;
import tsdb.util.CSV;
import tsdb.util.iterator.TsIterator;
import de.umr.jepc.util.Timer;

/**
 * Testing empirical diff check.
 * @author woellauer
 *
 */
public class UseCaseAverageGeneralStationQuery {
	
	private static final String CSV_OUTPUT_PATH = TsDBFactory.get_CSV_output_path();
	
	private static Function<TsEntry, TsEntry> createDiffFunc(TsIterator compareIt) {
		return new Function<TsEntry, TsEntry>() {			
			@Override
			public TsEntry apply(TsEntry element) {
				TsEntry genElement = compareIt.next();
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
				return new TsEntry(timestamp,result);
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
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		
		for(GeneralStation generalStation:timeSeriesDatabase.getGeneralStations()) {
			String streamName = generalStation.name;
			Long begin = null;
			Long end = null;
			ConcurrentNavigableMap<Long, TsEntry> map = timeSeriesDatabase.cacheStorage.queryMap(streamName, begin, end);
			System.out.println(generalStation.name+": "+TimeConverter.oleMinutesToLocalDateTime(map.firstKey())+"\t-\t"+TimeConverter.oleMinutesToLocalDateTime(map.lastKey()));
			Timer timer = new Timer();
			timer.start(generalStation.name);
			int count = 0;
			for(TsEntry value:map.values()) {
				count++;
			}
			timer.stop(generalStation.name);
			//System.out.println(count+"\t\t"+timer.toString(generalStation.name));
			
		}
		
		
		//String plotID = "SEW07";
		String plotID = "HEG04";
		String sensorName = "Ts_5";
		String[] querySchema = new String[]{sensorName};
		//Long queryStart = 56936340l;
		//Long queryEnd = 59809800l;
		long[] interval = timeSeriesDatabase.getBaseTimeInterval(plotID);
		Long queryStart = interval[0];
		Long queryEnd = interval[1];
		DataQuality dataQuality = DataQuality.STEP;


		
		CSV.write(qp.query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality), CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_org.csv");
		CSV.write(qp.query_empirical_diff_check(plotID, querySchema, queryStart, queryEnd, dataQuality), CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_check.csv");
		String generalName = timeSeriesDatabase.getStation(plotID).generalStation.name;
		CSV.write(Builder.project(timeSeriesDatabase.cacheStorage.query(generalName, queryStart, queryEnd),querySchema), CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_general.csv");
		TsIterator input_it = qp.query_continuous_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality);
		TsIterator diff_it = Builder.apply(input_it,createDiffFunc(Builder.project(Builder.continuous(timeSeriesDatabase.cacheStorage.query(generalName, queryStart, queryEnd), queryStart, queryEnd), input_it)));
		CSV.write(diff_it, CSV_OUTPUT_PATH+"UseCaseAverageGeneralStationQuery_diff.csv");
		
		
		System.out.println("...end");
	}

}
