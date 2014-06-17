package timeseriesdatabase;

import java.io.IOException;
import java.time.LocalDateTime;

import de.umr.eventstore.Stream;
import de.umr.eventstore.processors.CSVProcessor;
import de.umr.eventstore.processors.ProcessingEngine;
import de.umr.eventstore.processors.Processor;
import de.umr.eventstore.queries.Query;
import de.umr.eventstore.queries.SQLQuery;
import de.umr.eventstore.storage.Schema;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

public class UseCaseBasisAggregation {

	public static void main(String[] args) {
System.out.println("begin...");
		
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		
		String plotID = "HEG31";
		TimeSeries timeSeries = timeSeriesDatabase.queryBasisData(plotID);
		
		timeSeries.writeToCSV("k:/output/result.csv", " ", "NaN", true);
		
		System.out.println(timeSeries);
		
		
		System.out.println("...end");

	}

}
