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

/**
 * Generates time series for general stations with average of contained station values
 * and stores it in cache database.
 * @author woellauer
 *
 */
public class UseCaseAverageGeneralStationGenerate {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";	
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		DataQuality dataquality = DataQuality.STEP;


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
			System.out.println(generalStation.name+" ********************************* "+TimeConverter.oleMinutesToLocalDateTime(generalMinTimestamp)+"\t - \t"+TimeConverter.oleMinutesToLocalDateTime(generalMaxTimestamp)+" **************************************************************** "+generalMinTimestamp+"\t-\t"+generalMaxTimestamp);
			List<TimeSeriesIterator> iteratorList = new ArrayList<TimeSeriesIterator>();
			for(Station station:generalStation.stationList) {
				TimeSeriesIterator it = qp.query_continuous_base_aggregated(station.stationID, null, generalMinTimestamp, generalMaxTimestamp, dataquality);
				if(it!=null) {
					iteratorList.add(it);
				}
			}

			String[] generalSchema = generalSchemaSet.toArray(new String[0]);
			AverageIterator result_iterator = new AverageIterator(generalSchema,iteratorList.toArray(new TimeSeriesIterator[0]),3);
			//CSV.write(result_iterator, CSV_OUTPUT_PATH+"UseCaseAverageGeneralStation_"+generalStation.name+".csv");
			
			timeSeriesDatabase.cacheStorage.writeNew(generalStation.name, result_iterator);

		}






		System.out.println("...end");
	}
}
