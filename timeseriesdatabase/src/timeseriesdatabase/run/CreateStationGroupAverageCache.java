package timeseriesdatabase.run;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import javax.print.attribute.HashAttributeSet;

import processinggraph.Averaged;
import processinggraph.Base;
import processinggraph.Continuous;
import processinggraph.RawSource;
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
import timeseriesdatabase.aggregated.BaseAggregationTimeUtil;
import timeseriesdatabase.aggregated.iterator.AverageIterator;
import timeseriesdatabase.aggregated.iterator.NanRemoveIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.CSV;
import util.CSVTimeType;
import util.Util;
import util.iterator.TimeSeriesIterator;
import util.iterator.TimeSeriesIteratorIterator;

/**
 * Generates time series for general stations with average of contained station values
 * and stores it in cache database.
 * @author woellauer
 *
 */
public class CreateStationGroupAverageCache {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";	

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		DataQuality dataquality = DataQuality.STEP;
		
		
		for(String group:timeSeriesDatabase.getGeneralStationGroups()) {
			List<String> list = timeSeriesDatabase.getStationAndVirtualPlotNames(group).collect(Collectors.toList());
			System.out.println(group+" -> "+list);
			
			long generalMinTimestamp = Long.MAX_VALUE;
			long generalMaxTimestamp = Long.MIN_VALUE;
			for(String plotID:list) {
				Base node = Base.create(timeSeriesDatabase, plotID, null);
				TimeSeriesIterator it = node.get(null, null);
				if(it==null||!it.hasNext()) {
					continue;
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
			
			if(generalMinTimestamp!=Long.MAX_VALUE && generalMaxTimestamp!=Long.MIN_VALUE) {
				System.out.println(group+" ********************************* "+TimeConverter.oleMinutesToLocalDateTime(generalMinTimestamp)+"\t - \t"+TimeConverter.oleMinutesToLocalDateTime(generalMaxTimestamp)+" **************************************************************** "+generalMinTimestamp+"\t-\t"+generalMaxTimestamp);
				generalMinTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(generalMinTimestamp);
				generalMaxTimestamp = BaseAggregationTimeUtil.calcBaseAggregationTimestamp(generalMaxTimestamp);
				List<Continuous> sources = new ArrayList<Continuous>();
				for(String plotID:list) {
					Continuous continuous = Continuous.create(timeSeriesDatabase, plotID, null, dataquality);
					sources.add(continuous);
				}				
				Averaged averaged = Averaged.create(timeSeriesDatabase, sources);
				TimeSeriesIterator result_iterator = averaged.get(generalMinTimestamp, generalMaxTimestamp);
				timeSeriesDatabase.cacheStorage.writeNew(group, result_iterator);
				//averaged.writeConsole(generalMinTimestamp, generalMaxTimestamp);

			}
			
			
			
			
		}
		

/*
		for(GeneralStation generalStation:timeSeriesDatabase.getGeneralStations()) {
			

			
			
			
			long generalMinTimestamp = Long.MAX_VALUE;
			long generalMaxTimestamp = Long.MIN_VALUE;
			TreeSet<String> generalSchemaSet = new TreeSet<String>();
			for(Station station:generalStation.stationList) {
				TimeSeriesIterator it = qp.query_raw(station.stationID, null, null, null);
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

			if(generalMinTimestamp!=Long.MAX_VALUE && generalMaxTimestamp!=Long.MIN_VALUE) {
				System.out.println(generalStation.name+" ********************************* "+TimeConverter.oleMinutesToLocalDateTime(generalMinTimestamp)+"\t - \t"+TimeConverter.oleMinutesToLocalDateTime(generalMaxTimestamp)+" **************************************************************** "+generalMinTimestamp+"\t-\t"+generalMaxTimestamp);
				List<TimeSeriesIterator> iteratorList = new ArrayList<TimeSeriesIterator>();
				for(Station station:generalStation.stationList) {
					//TimeSeriesIterator it = qp.query_continuous_base_aggregated(station.stationID, null, generalMinTimestamp, generalMaxTimestamp, dataquality);
					Continuous continuous = Continuous.create(timeSeriesDatabase, station.stationID, null, dataquality);
					TimeSeriesIterator it = continuous.get(generalMinTimestamp, generalMaxTimestamp);
					if(it!=null) {
						iteratorList.add(it);
					}
				}

				String[] generalSchema = generalSchemaSet.toArray(new String[0]);
				AverageIterator result_iterator = new AverageIterator(generalSchema,iteratorList.toArray(new TimeSeriesIterator[0]),3);
				//CSV.write(result_iterator, CSV_OUTPUT_PATH+"UseCaseAverageGeneralStation_"+generalStation.name+".csv");

				timeSeriesDatabase.cacheStorage.writeNew(generalStation.name, result_iterator);

			}
		}*/



		timeSeriesDatabase.close();


		System.out.println("...end");
	}
}
