package usecase;

import timeseriesdatabase.CSVTimeType;
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
		
		SchemaIterator<TimestampSeriesEntry> it = timeSeriesDatabase.queryTesting(plotID,sensorNames,null,null,true,true,true);
		while(it.hasNext()) {
			TimestampSeriesEntry e = it.next();
			System.out.println(e);
			//System.out.print(e.timestamp+" ");
			//Util.printArray(e.data);
		}
		
		
		TimeSeries timeSeries = timeSeriesDatabase.queryGapFilledTesting(plotID,sensorNames,null,null,true,true,true);
		
		System.out.println(timeSeries);
		
		String nanValue = "NaN";
		
		timeSeries.writeToCSV("c:/timeseriesdatabase_output/result.csv", " ", nanValue, CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		
		System.out.println("...end");
	}

}
