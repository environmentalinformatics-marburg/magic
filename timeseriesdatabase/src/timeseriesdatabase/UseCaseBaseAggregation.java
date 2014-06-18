package timeseriesdatabase;

import java.io.IOException;
import java.time.LocalDateTime;

import timeseriesdatabase.TimeSeries.CSVTimeType;
import de.umr.eventstore.Stream;
import de.umr.eventstore.processors.CSVProcessor;
import de.umr.eventstore.processors.ProcessingEngine;
import de.umr.eventstore.processors.Processor;
import de.umr.eventstore.queries.Query;
import de.umr.eventstore.queries.SQLQuery;
import de.umr.eventstore.storage.Schema;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

public class UseCaseBaseAggregation {

	public static void main(String[] args) {
		System.out.println("begin...");
		
		System.out.println("start database...");

		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();

		System.out.println("query data...");
		
		String plotID = "HEG31";
		LocalDateTime start = LocalDateTime.of(2013,01,01,0,0);
		LocalDateTime end = LocalDateTime.of(2013,01,31,23,59);
		long startTimestamp = TimeConverter.DateTimeToOleMinutes(start);
		long endTimestamp = TimeConverter.DateTimeToOleMinutes(end);
		
		TimeSeries timeSeries = timeSeriesDatabase.queryBasisData(plotID,startTimestamp,endTimestamp);
		//TimeSeries timeSeries = timeSeriesDatabase.queryRawData(plotID);

		
		System.out.println("print part of timeseries...");

		System.out.println(timeSeries);
		
		System.out.println("write data to file...");

		timeSeries.writeToCSV("k:/output/result.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);
		
		System.out.println("...end");

		//timeSeriesDatabase.close();

	}

}
