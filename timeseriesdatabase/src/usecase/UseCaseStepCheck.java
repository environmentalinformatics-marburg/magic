package usecase;

import java.util.Iterator;

import de.umr.jepc.store.Event;
import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.NanGapIterator;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeriesEntry;
import util.SchemaIterator;
import util.Util;

public class UseCaseStepCheck {
	
	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String plotID = "HEG01";
		//String[] sensorNames = new String[]{"Ta_200"};
		String[] sensorNames = new String[]{"rH_200"};
		/*
		//SchemaIterator<TimestampSeriesEntry> it = timeSeriesDatabase.queryTesting(plotID,sensorNames,null,null,true,true,true);	
		
		SchemaIterator<TimestampSeriesEntry> it = timeSeriesDatabase.queryBaseAggregatedTesting(plotID,sensorNames,null,null,true,true,true);
		
		it = new NanGapIterator(timeSeriesDatabase, it);
		
		
		while(it.hasNext()) {
			TimestampSeriesEntry e = it.next();
			//System.out.println(e);
			//System.out.print(e.timestamp+" ");
			//Util.printArray(e.data);
		}
		
		*/
		
		
		//SchemaIterator<TimestampSeriesEntry> it = timeSeriesDatabase.queryRaw(plotID,sensorNames,null,null);
		SchemaIterator<TimestampSeriesEntry> it = qp.queryQualityChecked(plotID,sensorNames,null,null,false,false,true);
		//SchemaIterator<TimestampSeriesEntry> it = timeSeriesDatabase.queryBaseAggregated(plotID,sensorNames,null,null,false,false,false);
		while(it.hasNext()) {
			TimestampSeriesEntry e = it.next();
			System.out.println(e);
			//System.out.print(e.timestamp+" ");
			//Util.printArray(e.data);
		}
		
		/*Iterator<Event> it = timeSeriesDatabase.query("SELECT rH_200 FROM HEG01");
		while(it.hasNext()) {
			System.out.println(it.next());
		}*/
		
		
		TimeSeries timeSeries = qp.queryGapFilledTimeSeries(plotID,sensorNames,null,null,true,true,true);
		
		System.out.println(timeSeries);
		
		String nanValue = "NaN";
		
		timeSeries.writeToCSV("c:/timeseriesdatabase_output/result.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		
		System.out.println("...end");
	}

}
