package usecase;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;

import javax.print.attribute.HashAttributeSet;

import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;
import de.umr.jepc.util.enums.TimeRepresentation;
import timeseriesdatabase.DataQuality;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.iterator.AverageIterator;
import timeseriesdatabase.aggregated.iterator.NanRemoveIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.CSV;
import util.CSVTimeType;
import util.Util;
import util.iterator.TimeSeriesIterator;
import util.iterator.TimeSeriesIteratorIterator;

public class UseCaseAverageGeneralStationGenerate {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";	
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		DataQuality dataquality = DataQuality.STEP;

		/*
		//String plotID = "HEG01";
		//String plotID = "HEG20";
		//String plotID = "HEW12";
		//String[] querySchema = new String[]{"Ta_200"};
		String[] querySchema = new String[]{"Ta_200","rH_200","Ta_10","Ts_5","Ts_10","Ts_20","Ts_50","SM_10","SM_15","SM_20"};
		//String[] querySchema = null;
		Long queryStart = null;
		Long queryEnd = null;
		 */

		/*String[] generalStationNames = new String[]{"HEG","HEW"};

		for(String generalStationName:generalStationNames) {

			GeneralStation generalStation = timeSeriesDatabase.generalStationMap.get(generalStationName);
			List<Station> stationList = generalStation.stationList;

			//TimeSeriesIterator it = TimeSeriesIteratorIterator.create(stationList, station -> new NanRemoveIterator(qp.queryRawQualityChecked(station.plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange)));
			TimeSeriesIterator it = TimeSeriesIteratorIterator.create(stationList, station -> new NanRemoveIterator(qp.query_raw_with_bad_quality_removed(station.plotID, querySchema, queryStart, queryEnd, DataQuality.STEP)));

			//TimeSeriesIterator it = qp.queryRaw(plotID, querySchema, queryStart, queryEnd);		
			//TimeSeriesIterator it = qp.queryQualityChecked(plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
			//TimeSeriesIterator it = qp.queryAggregated(plotID, querySchema, start, end, AggregationInterval.DAY, false, false, false, false);
			CSV.writeNoHeader(it, "c:/timeseriesdatabase_output/empirical_range_"+generalStationName+".csv", ",", "?", CSVTimeType.TIMESTAMP);


		}*/

		for(GeneralStation generalStation:timeSeriesDatabase.generalStationMap.values()) {
			long generalMinTimestamp = Long.MAX_VALUE;
			long generalMaxTimestamp = Long.MIN_VALUE;
			TreeSet<String> generalSchemaSet = new TreeSet<String>();
			for(Station station:generalStation.stationList) {
				TimeSeriesIterator it = qp.query_raw(station.plotID, null, null, null);
				if(it!=null) {

					String[] schema = it.getOutputSchema();
					for(String name:schema) {
						generalSchemaSet.add(name);
					}
					while(it.hasNext()) {				
						TimeSeriesEntry element = it.next();
						if(element.timestamp<generalMinTimestamp) {
							generalMinTimestamp = element.timestamp;
						}
						if(generalMaxTimestamp<element.timestamp) {
							generalMaxTimestamp = element.timestamp;
						}
					}
				}
			}
			System.out.println(generalStation.name+" ********************************* "+TimeConverter.oleMinutesToLocalDateTime(generalMinTimestamp)+"\t - \t"+TimeConverter.oleMinutesToLocalDateTime(generalMaxTimestamp)+" **************************************************************** "+generalMinTimestamp+"\t-\t"+generalMaxTimestamp);
			List<TimeSeriesIterator> iteratorList = new ArrayList<TimeSeriesIterator>();
			for(Station station:generalStation.stationList) {
				TimeSeriesIterator it = qp.query_continuous_base_aggregated(station.plotID, null, generalMinTimestamp, generalMaxTimestamp, dataquality);
				if(it!=null) {
					iteratorList.add(it);
				}
			}

			String[] generalSchema = generalSchemaSet.toArray(new String[0]);
			AverageIterator result_iterator = new AverageIterator(generalSchema,iteratorList.toArray(new TimeSeriesIterator[0]));
			//CSV.write(result_iterator, CSV_OUTPUT_PATH+"UseCaseAverageGeneralStation_"+generalStation.name+".csv");
			
			timeSeriesDatabase.cacheStorage.writeNew(generalStation.name, result_iterator);
			
			/*Attribute[] generalAttributes = timeSeriesDatabase.createAttributes(generalSchema);			
			timeSeriesDatabase.streamStorage.registerStream(generalStation.name, generalAttributes);
			TreeMap<Long, Event> eventMap = new TreeMap<Long, Event>();
			while(result_iterator.hasNext()) {
				TimeSeriesEntry element = result_iterator.next();
				eventMap.put(element.timestamp, new Event(Util.array_float_to_array_Float(element.data), element.timestamp));
			}
			timeSeriesDatabase.streamStorage.insertData(generalStation.name, eventMap );*/
			
		}






		System.out.println("...end");
	}
}
